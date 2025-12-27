# Plan A Infrastructure Workflow

This repo uses a layered deployment strategy to keep global AWS resources stable while still shipping app changes quickly.

## AWS Deployment Flow
1. **Stage 1 (ACM)**: Provision/validate CloudFront certificates.
2. **Stage 2 (CDN)**: Create/update CloudFront distribution and DNS records.
3. **Application (Kustomize)**: Deploy namespace-scoped Kubernetes resources.

### Workflow Mapping
- Stage 1: `.github/workflows/terraform-aws-stage1-acm.yml`
- Stage 2: `.github/workflows/terraform-aws-stage2-cdn.yml`
- Application: `.github/workflows/kustomize-deploy.yml`

### Why This Split
- Reduces blast radius: app edits do not re-run global infra layers.
- Speeds feedback: infra stages can be skipped unless relevant files change.
- Clear dependency chain: ACM → CDN → Kustomize.

### Inputs and Outputs
- Stage 1 outputs the CloudFront ACM certificate ARN.
- Stage 2 consumes the Stage 1 output and updates CloudFront/DNS.
- Kustomize deploy runs only after both infra stages succeed.

---

## GCP Hub-and-Spoke Architecture

GCP infrastructure uses a Hub-and-Spoke pattern for project orchestration:

### Architecture
```
hub/                     # Master project - manages WIF and creates spoke projects
├── main.tf              # TFC workspace: lornu-ai-hub
├── iam.tf               # WIF bindings and permissions
└── spoke-projects.tf    # Spoke project definitions

agent-spoke/             # App-specific infrastructure (AI Agent workloads)
├── main.tf              # TFC workspace: lornu-agent-spoke
├── variables.tf
└── outputs.tf
```

### Hub Project (`hub/`)
- **Workspace**: `lornu-ai-hub`
- **Responsibilities**:
  - Manages Workload Identity Federation pool and providers
  - Creates and provisions spoke projects
  - Grants WIF bindings for spoke workspaces
  - Holds org-level permissions (project creator, billing user)

### Spoke Projects
Each spoke project is created by the Hub and has:
- Its own TFC workspace for infrastructure management
- Dedicated service account with WIF bindings
- Scoped permissions within its project only

**Current Spokes**:
| Spoke | Directory | TFC Workspace | Purpose |
|-------|-----------|---------------|---------|
| Agent | `agent-spoke/` | `lornu-agent-spoke` | AI Agent runtime (GKE, Artifact Registry) |

### Workflow Mapping
- Hub: `.github/workflows/hub-infra.yaml`
- Agent Spoke: `.github/workflows/agent-infra.yaml`

### OIDC Authentication
All GCP workspaces use Workload Identity Federation for passwordless authentication:
- No static service account keys
- TFC workspaces authenticate via OIDC tokens
- See `docs/OIDC_MIGRATION_RUNBOOK.md` for setup details
