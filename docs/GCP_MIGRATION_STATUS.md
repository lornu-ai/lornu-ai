# 🚀 GCP Migration Status & Roadmap

This document tracks the progress of the infrastructure migration from AWS to GCP/GKE and outlines the remaining steps to achieve a fully automated "Plan A" environment.

## 📊 Current Status
| Component | Status | Mechanism |
|-----------|---------|-----------|
| **VPC & Networking** | ✅ Ready | Terraform |
| **GKE Cluster (Autopilot)** | ✅ Ready | Terraform |
| **Firestore Database** | ✅ Ready | Terraform |
| **Artifact Registry** | ✅ Ready | Terraform |
| **Cloud DNS Zone** | ✅ Ready | Terraform |
| **IAM Service Accounts** | 🟡 Partial | Terraform (Import Pending) |
| **Workload Identity** | 🟡 Pending | Terraform |
| **CI/CD Workflows** | ✅ Ready | GitHub Actions |

---

## 🛠 Required Actions (Roadmap)

### Step 1: Adopt the Provisioner Identity 🔐
Terraform needs to "own" the existing `terraform-provisioner` service account to manage its keys and high-level roles (`dns.admin`, etc.).

- [ ] **Action**: Run the `GCP Terraform Service Account Setup` workflow with `import_sa`.
- [ ] **Status**: Failing with variable conflicts. Needs a fix to the workflow triggers.

### Step 2: Grant Extended Permissions 🎫
Once the SA is imported, we need to run a full Terraform apply to grant the new roles required for Artifact Registry and DNS.

- [ ] **Action**: Run `GCP Terraform Deployment` workflow.
- [ ] **Expectation**: Terraform will add `roles/artifactregistry.admin` and `roles/dns.admin` to the provisioner.

### Step 3: Rotate Security Keys 🔄
We are moving to a model where Terraform generates the JSON key for CI/CD.

- [ ] **Action**: Run `GCP Terraform Service Account Setup` with `output_key`.
- [ ] **Action**: Update GitHub Secret `GCP_CREDENTIALS_JSON` with the new Base64 value.

### Step 4: First Application Deploy 🚀
Once the Artifact Registry and GKE permissions are fully established:

- [ ] **Action**: Trigger `GKE Build & Deploy` workflow.
- [ ] **Target**: `lornu-dev` namespace in GKE.

---

## 📝 Troubleshooting & Notes
- **Drift Detection**: The `GCP Terraform Drift Check` workflow is now active and will alert us if any manual changes are made in the GCP Console.
- **Terraform Version**: All GCP workflows are now locked to **v1.14** to match Terraform Cloud.
- **Workload Identity**: In Step 4, we will verify that the `lornu-backend` SA can successfully access Firestore and Vertex AI from within the cluster.
