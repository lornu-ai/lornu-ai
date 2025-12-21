This design document outlines the architectural transition and infrastructure provisioning required to establish an **AWS Staging Environment** for Lornu AI. This move supports a multi-cloud strategy, providing a failover and testing ground for the core FastAPI/ADK Agent logic currently residing in GCP and Cloudflare.

---

### 1. Compute Strategy Decision Matrix
Based on the objective to de-risk Cloudflare Workers while maintaining the performance of the **FastAPI/ADK Agent** backend, the following evaluation is set:

| Feature | AWS Lambda | AWS ECS (Fargate) | AWS EKS |
| :--- | :--- | :--- | :--- |
| **Complexity** | Low | Medium | High |
| **Agent Suitability** | Poor (Timeout/Cold Starts) | **Excellent (Long-lived)** | Overkill for Staging |
| **Cost** | Pay-per-request | Balanced (Serverless) | High (Control Plane) |
| **Scaling** | Instant (but limited) | Rapid (Horizontal) | Highly Granular |

**Recommendation**: **AWS ECS (Fargate)**.
*   **Reasoning**: ECS Fargate provides a serverless container experience that mirrors our GCP Cloud Run setup. It natively supports long-lived connections required for streaming LLM responses (Gemini) and the ADK Agent's `process()` execution cycles, which often exceed Lambda’s optimal duration.

---

### 2. Containerization Design (Bun + Node.js/Python)
The Lornuai worker/API will be unified into a Docker image. While the backend uses Python/FastAPI, the orchestration and frontend build utilize **Bun**.

**File**: `/Dockerfile`
```dockerfile
# Multi-stage build for Lornu AI
FROM oven/bun:alpine AS base
WORKDIR /app

# Stage 1: Build Frontend (if bundled)
COPY frontend/package.json frontend/bun.lockb ./frontend/
RUN cd frontend && bun install --frozen-lockfile
COPY frontend/ ./frontend/
RUN cd frontend && bun run build

# Stage 2: Backend Execution (Python 3.11+ for ADK)
FROM python:3.11-slim
WORKDIR /app
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Install dependencies
COPY backend/pyproject.toml backend/uv.lock ./
RUN uv sync --frozen

# Copy Application logic
COPY backend/ ./backend/
COPY --from=base /app/frontend/dist ./frontend/dist

# Environment variables for A2A and Gemini
ENV PORT=8080
EXPOSE 8080

CMD ["uv", "run", "python", "-m", "backend.main"]
```

---

### 3. Terraform Infrastructure Design (AWS Staging)
The infrastructure will be modularized under `terraform/aws/staging/` to ensure isolation.

**Directory Structure**:
```text
terraform/aws/staging/
├── main.tf          # Provider & Terraform Cloud Backend
├── vpc.tf           # VPC, Subnets, IGW, NAT
├── iam.tf           # Task Execution Roles
├── ecs.tf           # Cluster, Service, Task Definition
├── alb.tf           # Application Load Balancer
└── variables.tf     # Environment specific variables
```

**Key Resource Definitions**:
*   **VPC**: 10.1.0.0/16 CIDR block.
*   **Subnets**: 2x Public (for ALB), 2x Private (for ECS Tasks).
*   **Security Groups**: Port 80/443 ingress for ALB; Port 8080 ingress for ECS from ALB.
*   **Secrets**: Integration with **AWS Secrets Manager** to store Gemini API Keys and GCP Service Account keys (for Firestore access).

---

### 4. CI/CD Integration Plan (GitHub Actions)
A new workflow `.github/workflows/terraform-aws.yml` will manage the infrastructure lifecycle.

**Workflow Logic**:
1.  **Trigger**: PRs targeting `main` or manual dispatch.
2.  **Auth**: Use `aws-actions/configure-aws-credentials` with OIDC (preferred over static keys).
3.  **TFC**: `terraform init` linked to the Lornu AI organization in Terraform Cloud.
4.  **Security**: `trivy` or `tfsec` scan on the Terraform plan.
5.  **Apply**: Manual approval gate required for `terraform apply` on the staging environment.

---

### 5. Task Breakdown & Implementation Steps

#### Phase A: Research & Planning (Documentation)
- [ ] Create `docs/aws-compute-strategy.md` detailing the ECS Fargate decision.
- [ ] Document cross-cloud data access strategy (AWS ECS → GCP Firestore).

#### Phase B: Containerization
- [ ] Implement the multi-stage Dockerfile using `uv` and `bun`.
- [ ] Verify image locally using `podman build`.

#### Phase C: Terraform Provisioning
- [ ] **Networking**: Deploy VPC, NAT Gateway, and Subnets.
- [ ] **IAM**: Create `LornuEcsTaskRole` with permissions for CloudWatch Logs and Secrets Manager.
- [ ] **Compute**: Define ECS Cluster and Fargate Service.
- [ ] **State**: Connect `terraform/aws/staging/` to Terraform Cloud.

#### Phase D: Validation & Testing
- [ ] **Health Check**: Ensure the `/health` endpoint of the FastAPI backend returns `200 OK` behind the AWS ALB.
- [ ] **Integration Test**: Verify the ADK Agent can successfully reach the Gemini API from the AWS VPC.
- [ ] **Coverage**: Ensure AWS-specific deployment scripts are covered by infrastructure tests (targeting 70%+ config validation).

---

### 6. Security & Multi-Cloud Considerations
*   **Zero Trust**: All A2A Protocol traffic between AWS and GCP must be authenticated via JWT or mTLS.
*   **State Consistency**: During staging, the AWS environment will point to a dedicated `staging` Firestore database in GCP to prevent data pollution.
*   **IAM Policy**: Use the Principle of Least Privilege (PoLP) for the ECS Task execution role, specifically limiting access to only the necessary AWS Secrets Manager paths.
