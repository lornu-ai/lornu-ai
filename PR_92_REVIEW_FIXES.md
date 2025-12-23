# PR #92 Code Review Fixes

This document summarizes all Copilot code review comments on PR #92 and recommended fixes.

## 1. GitHub Workflow (.github/workflows/terraform-aws.yml)

### Issue 1.1: Terraform version pinning
**Comment**: Line 27 - Terraform version 1.8.0 may not be latest
**Fix**:
```yaml
terraform_version: ~> 1.8  # Allow patch updates instead of pinned to 1.8.0
```

### Issue 1.2: Missing job dependency
**Comment**: Line 43 - 'apply' job lacks dependency on 'plan' job
**Fix**:
```yaml
apply:
  name: "Terraform Apply"
  runs-on: ubuntu-latest
  needs: plan  # Add this line
  if: github.event_name == 'workflow_dispatch'
```

---

## 2. ALB Configuration (terraform/aws/staging/alb.tf)

### Issue 2.1: Incomplete health check
**Comment**: Target group health check missing critical parameters
**Fix**:
```hcl
health_check {
  path                = "/health"
  timeout             = 5
  interval            = 30
  healthy_threshold   = 3
  unhealthy_threshold = 3
}
```

### Issue 2.2: Outdated SSL policy
**Comment**: 'ELBSecurityPolicy-2016-08' is outdated
**Fix**:
```hcl
ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"  # Use modern security policy
```

### Issue 2.3: Security group missing lifecycle management
**Comment**: Security group needs name_prefix or lifecycle block
**Fix**:
```hcl
resource "aws_security_group" "alb" {
  name_prefix = "lornu-ai-staging-alb-"
  description = "Allow inbound HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.main.id

  lifecycle {
    create_before_destroy = true
  }
  # ... rest of config
}
```

---

## 3. ECS Configuration (terraform/aws/staging/ecs.tf)

### Issue 3.1: Missing CloudWatch logs
**Comment**: ECS task definition lacks CloudWatch Logs configuration
**Fix**:
```hcl
container_definitions = jsonencode([
  {
    name  = "lornu-ai-staging-container"
    image = var.docker_image
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
    # ... rest of config
  }
])
```

Add log group resource:
```hcl
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/lornu-ai-staging"
  retention_in_days = 14
}
```

### Issue 3.2: ECS service missing listener dependency
**Comment**: Service needs dependency on load balancer listener
**Fix**:
```hcl
resource "aws_ecs_service" "main" {
  name            = "lornu-ai-staging-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # ... network configuration ...

  depends_on = [aws_lb_listener.https]  # Add this
}
```

### Issue 3.3: Security group missing lifecycle management
**Fix**: Apply same pattern as alb.tf - use `name_prefix` and `lifecycle` block

---

## 4. IAM Configuration (terraform/aws/staging/iam.tf)

### Issue 4.1: Hardcoded role names (no environment suffix)
**Comment**: IAM role names conflict across environments
**Fix**:
```hcl
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "LornuEcsTaskExecutionRole-${var.environment}"  # Add environment suffix
}

resource "aws_iam_role" "ecs_task_role" {
  name = "LornuEcsTaskRole-${var.environment}"  # Add environment suffix
}
```

### Issue 4.2: Hardcoded policy names (no environment suffix)
**Fix**:
```hcl
resource "aws_iam_policy" "secrets_manager_access" {
  name = "LornuSecretsManagerAccess-${var.environment}"  # Add environment suffix
}
```

---

## 5. Variables Configuration (terraform/aws/staging/variables.tf)

### Issue 5.1: Missing default for ACM certificate
**Comment**: acm_certificate_arn is required but has no default
**Fix**:
```hcl
variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate to use for the ALB."
  type        = string
  # Suggestion: Use validation or add sensible default
  validation {
    condition     = can(regex("^arn:aws:acm:", var.acm_certificate_arn))
    error_message = "Must be a valid ACM certificate ARN"
  }
}
```

### Issue 5.2: Missing default for secrets manager ARN
**Comment**: secrets_manager_arn_pattern is required but has no default
**Fix**:
```hcl
variable "secrets_manager_arn_pattern" {
  description = "The ARN pattern for secrets the application needs to access."
  type        = string
  default     = "arn:aws:secretsmanager:*:*:secret:*"  # Add sensible default
}
```

---

## 6. VPC Configuration (terraform/aws/staging/vpc.tf)

### Issue 6.1: VPC missing DNS configuration
**Comment**: VPC needs DNS hostnames and support for ECS task resolution
**Fix**:
```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true  # Add this
  enable_dns_support   = true  # Add this

  tags = {
    Name = "lornu-ai-staging-vpc"
  }
}
```

### Issue 6.2: Public subnets missing public IP auto-assignment
**Comment**: ALB and NAT require public IPs
**Fix**:
```hcl
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true  # Add this

  tags = {
    Name = "lornu-ai-staging-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true  # Add this

  tags = {
    Name = "lornu-ai-staging-public-b"
  }
}
```

### Issue 6.3: NAT Gateway missing IGW dependency
**Comment**: NAT Gateway depends on Internet Gateway being attached
**Fix**:
```hcl
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  depends_on = [aws_internet_gateway.main]  # Add this

  tags = {
    Name = "lornu-ai-staging-nat"
  }
}
```

---

## 7. Dockerfile

### Issue 7.1: Incorrect path references
**Comments**: References 'frontend/' and 'backend/' but actual paths are 'apps/web/' and 'packages/api/'
**Fix**: All paths must match actual repository structure
```dockerfile
# Correct paths:
COPY apps/web/package.json apps/web/bun.lockb* ./apps/web/
COPY apps/web/ ./
RUN bun run build

# ... later in file ...

COPY packages/api/pyproject.toml packages/api/uv.lock ./packages/api/
COPY packages/api/ ./
COPY --from=frontend-builder /app/apps/web/dist ./public/
```

### Issue 7.2: Mutable uv image tag
**Comment**: ':latest' tag is unsafe, pin to specific version
**Status**: Already fixed in PR - using `ghcr.io/astral-sh/uv:0.5.11` ✓

### Issue 7.3: Incorrect module path in CMD
**Comment**: References 'backend.main' but should be 'main' in /app/packages/api
**Fix**:
```dockerfile
ENV PYTHONPATH=/app/packages/api
CMD ["uv", "run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
```

---

## Summary of Changes by Priority

### Critical (Will cause build/deploy failures)
- ✅ Dockerfile path corrections (apps/web, packages/api)
- ✅ Dockerfile PYTHONPATH and CMD fixes
- ⚠️ Terraform requires environment variable for acm_certificate_arn

### High (Security/operational issues)
- SSL policy update (ELBSecurityPolicy-2016-08 → ELBSecurityPolicy-TLS13-1-2-2021-06)
- CloudWatch logs configuration for ECS tasks
- DNS configuration for VPC

### Medium (Best practices)
- Add job dependencies (apply → plan)
- Add lifecycle management to security groups
- Add health check timeout/interval parameters
- Add NAT Gateway dependencies

### Low (Code quality)
- Environment-specific naming for IAM resources
- Terraform version constraint (~> 1.8)

---

## Validation Steps

After applying fixes:
1. Run `terraform plan` to validate configuration
2. Run `terraform validate` for syntax check
3. Build Docker image locally: `docker build .`
4. Check workflow syntax in GitHub Actions

