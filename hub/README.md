
# 🏗️ Lornu AI - Hub Infrastructure

This directory contains the Terraform configuration for the **Hub Project**. The Hub serves as the central management point for infrastructure orchestration, specifically handling:

*   **Workload Identity Federation (WIF)**: Linking GitHub Actions to Google Cloud securely.
*   **Service Accounts**: Configuring the `terraform-admin-sa` used for provisioning "Spoke" projects.
*   **IAM Policies**: Granting necessary permissions (Project Creator, Billing User) to the admin service account.

## 🚀 Automation & Workflow

Changes to this directory are automatically deployed via GitHub Actions.

### Workflow: GCP Hub Provisioning

**File Path**: `.github/workflows/hub-infra.yaml`

#### 🎯 Triggers
The workflow runs automatically under the following conditions:
*   **Event**: `pull_request`
*   **Branch**: `gcloud-oidc`
*   **Scope**: Only triggers when files inside the `hub/` directory are modified.

#### ⚙️ Process
The workflow executes the following steps on an `ubuntu-latest` runner:
1.  **Checkout**: Pulls the repository code.
2.  **Setup Terraform**: Configures the Terraform CLI using the `TF_API_TOKEN` secret for TFC authentication.
3.  **Init**: Initializes Terraform in the `./hub` working directory.
4.  **Apply**: Automatically applies changes (`-auto-approve`) to the infrastructure.

#### 🔑 Secrets & Variables
The following GitHub Secrets are injected as Terraform variables (`TF_VAR_...`):

| Terraform Variable | GitHub Secret Source | Description |
| :--- | :--- | :--- |
| `billing_account_id` | `GCP_BILLING_ID` | The ID of the billing account to attach to new projects. |
| `org_id` | `GCP_ORG_ID` | The ID of the GCP Organization. |
| `hub_project_id` | `GCP_HUB_PROJECT_ID` | The ID of the project hosting this Hub infrastructure. |

#### 📝 How to Deploy
Simply make your changes to the `.tf` files in this directory and open a pull request against the `gcloud-oidc` branch. The action will kickoff and then if all checks pass the pr merge to `gcloud-oidc`

```bash
git add hub/
git commit -m "feat: update hub infrastructure"
git push origin gcloud-oidc-develop
```
