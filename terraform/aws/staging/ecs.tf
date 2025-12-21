resource "aws_ecs_cluster" "main" {
  name = "lornu-cluster-${var.environment}"
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "lornu-ecs-tasks-sg-${var.environment}"
  description = "Allow inbound access from the ALB only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = var.container_port
    to_port         = var.container_port
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "/ecs/lornu-app-${var.environment}"
  retention_in_days = 14
}

resource "aws_ecs_task_definition" "app" {
  family                   = "lornu-app-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512" # 0.5 vCPU
  memory                   = "1024" # 1 GB
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "lornu-app"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.logs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
      environment = [
        { name = "ENVIRONMENT", value = var.environment }
      ]
      # Add Secrets here if var.secret_gemini_api_key_arn is set
      secrets = var.secret_gemini_api_key_arn != "" ? [
        {
          name      = "GEMINI_API_KEY"
          valueFrom = var.secret_gemini_api_key_arn
        }
      ] : []
    }
  ])
}

resource "aws_ecs_service" "main" {
  name            = "lornu-service-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "lornu-app"
    container_port   = var.container_port
  }

  desired_count = 1

  depends_on = [aws_lb_listener.http]
}
