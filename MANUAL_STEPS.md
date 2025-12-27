# Manual Steps to Resolve Terraform Cloud Permission Error

## The Problem: A "Chicken-and-Egg" Scenario

The Terraform Cloud workflow is failing because the identity it's using (a Workload Identity Federation principal) does not have the necessary permissions in Google Cloud to impersonate the target service account. The error message `Permission 'iam.serviceAccounts.getAccessToken' denied` indicates this.

We cannot fix this by adding the permission in the Terraform code itself because Terraform needs the permission *before* it can apply any changes. This creates a "chicken-and-egg" problem.

## The Solution: Manually Granting Permissions

To resolve this, you need to manually grant the `roles/iam.serviceAccountTokenCreator` role to the Terraform Cloud Workload Identity principal. This is a one-time setup step that allows the TFC identity to generate access tokens for the service account.

### Instructions

1.  **Identify your Project and Service Account:**
    *   `YOUR_HUB_PROJECT_ID`: The ID of your Google Cloud hub project.
    *   `YOUR_SERVICE_ACCOUNT_EMAIL`: The email of the service account Terraform is trying to manage (e.g., `tf-cloud-sa@your-hub-project-id.iam.gserviceaccount.com`).

2.  **Identify your Workload Identity Pool details:**
    *   `YOUR_PROJECT_NUMBER`: The number of your Google Cloud hub project. You can get this by running `gcloud projects describe YOUR_HUB_PROJECT_ID --format="value(projectNumber)"`.
    *   `YOUR_POOL_ID`: The ID of your Workload Identity Pool (e.g., `tfc-pool`).
    *   `YOUR_WORKSPACE_NAME`: The name of your Terraform Cloud workspace (e.g., `lornu-ai-hub`).

3.  **Open the Google Cloud Shell:** Go to the [Google Cloud Console](https://console.cloud.google.com/) and open the Cloud Shell.

4.  **Run the `gcloud` Command:** Execute the following command, replacing the placeholders with your actual values:

    ```bash
    gcloud iam service-accounts add-iam-policy-binding YOUR_SERVICE_ACCOUNT_EMAIL \\
        --project=YOUR_HUB_PROJECT_ID \\
        --role="roles/iam.serviceAccountTokenCreator" \\
        --member="principalSet://iam.googleapis.com/projects/YOUR_PROJECT_NUMBER/locations/global/workloadIdentityPools/YOUR_POOL_ID/attribute.terraform_workspace_name/YOUR_WORKSPACE_NAME"
    ```

5.  **Re-run the Terraform Plan:** Once the command is successful, go back to your Terraform Cloud workspace and re-run the plan. It should now have the necessary permissions to impersonate the service account and proceed.
