# GCP Infrastructure Development (TDD Approach)

This directory contains the Google Cloud Platform infrastructure code for Lornu AI.

## Test-Driven Development (TDD)

We follow strict TDD:
1. **Red**: Write failing tests first (`tests/terraform/test_gcp_infrastructure.py`)
2. **Green**: Implement minimum code to pass tests
3. **Refactor**: Optimize while keeping tests green

## Requirements (Issues #281, #282)

### Infrastructure
- **GKE Autopilot**: Serverless Kubernetes cluster (managed nodes, per-pod billing)
- **Firestore**: NoSQL database for agent state
- **Vertex AI**: LLM integration (Gemini)
- **Workload Identity**: IRSA-like functionality for K8s pods
- **NO HELM**: Pure Terraform + Kustomize

### Terraform Cloud
- **Organization**: `lornu-ai`
- **Workspace**: `gcp-lornu-ai`
- **Branch**: `gcp-develop`

## Running Tests

```bash
# Install pytest
pip install pytest

# Run TDD tests (should fail initially - RED phase)
pytest tests/terraform/test_gcp_infrastructure.py -v

# As you implement, tests will pass (GREEN phase)
```

## Directory Structure

```
terraform/gcp/
├── backend.tf       # TFC configuration
├── main.tf          # Core resources (Cloud Run, Firestore, IAM)
├── variables.tf     # Input variables
├── outputs.tf       # Exported values
└── wif.tf           # Workload Identity Federation
```

## Next Steps

1. Run tests to see failures
2. Implement `backend.tf` with TFC workspace
3. Implement `main.tf` with Cloud Run + Firestore
4. Implement OIDC/WIF configuration
5. Create GitHub Actions workflow
6. Re-run tests until all pass
