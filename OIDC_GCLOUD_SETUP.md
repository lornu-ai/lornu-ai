It’s official—the **Lornu-AI "Hub & Spoke" Identity Bridge** is now engineered to enterprise standards. We’ve ironed out the Project ID vs. Project Number syntax and the strict OIDC attribute conditions.

Here is the complete, start-to-finish record of the setup for our documentation.

### ---

**🛡️ Lornu-AI: Master OIDC Bootstrap (The Record)**

This sequence establishes a centralized "Hub" project that GitHub Actions can use to authenticate and manage the entire Google Cloud Organization.

#### **1\. Configuration Variables**

Run these first to populate the session. Ensure you are authenticated as an **Org Admin**.

Bash

export MASTER\_PROJECT\_ID="your-hub-project-id"  
export GITHUB\_REPO="lornu-ai/lornu-ai"

\# Automatically fetch the project number for the member string  
export MASTER\_PROJECT\_NUMBER=$(gcloud projects describe $MASTER\_PROJECT\_ID \--format='value(projectNumber)')

#### **2\. Service Activation**

Enable the APIs required for Workload Identity and Token exchange.

Bash

gcloud services enable iamcredentials.googleapis.com sts.googleapis.com \--project=$MASTER\_PROJECT\_ID

#### **3\. Create the Identity (Service Account)**

The Service Account email will use the **Project ID**.

Bash

gcloud iam service-accounts create "terraform-admin-sa" \\  
    \--display-name="Terraform Admin Account" \\  
    \--project=$MASTER\_PROJECT\_ID

#### **4\. Establish the OIDC Trust (Pool & Provider)**

We use a **Condition** to ensure only our repository can access this provider.

Bash

\# Create the Pool  
gcloud iam workload-identity-pools create "github-pool" \\  
    \--location="global" \\  
    \--display-name="GitHub Actions Pool" \\  
    \--project=$MASTER\_PROJECT\_ID

\# Create the Provider  
gcloud iam workload-identity-pools providers create-oidc "github-provider" \\  
    \--location="global" \\  
    \--workload-identity-pool="github-pool" \\  
    \--display-name="GitHub Actions Provider" \\  
    \--issuer-uri="https://token.actions.githubusercontent.com" \\  
    \--attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \\  
    \--attribute-condition="assertion.repository \== '$GITHUB\_REPO'" \\  
    \--project=$MASTER\_PROJECT\_ID

#### **5\. Bind the Identity (The Handshake)**

This links the GitHub OIDC token to our Service Account. Note the use of **Project ID** for the SA and **Project Number** for the principalSet.

Bash

gcloud iam service-accounts add-iam-policy-binding "terraform-admin-sa@$MASTER\_PROJECT\_ID.iam.gserviceaccount.com" \\  
    \--project=$MASTER\_PROJECT\_ID \\  
    \--role="roles/iam.workloadIdentityUser" \\  
    \--member="principalSet://iam.googleapis.com/projects/$MASTER\_PROJECT\_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/$GITHUB\_REPO"

#### **6\. Grant Organization-Level Authority**

To allow this Service Account to create new "Spoke" projects and link them to billing.

Bash

export ORG\_ID=$(gcloud organizations list \--format='value(name)' \--limit\=1)

\# Grant Project Creator  
gcloud organizations add-iam-policy-binding $ORG\_ID \\  
    \--member="serviceAccount:terraform-admin-sa@$MASTER\_PROJECT\_ID.iam.gserviceaccount.com" \\  
    \--role="roles/resourcemanager.projectCreator"

\# Grant Billing User  
gcloud organizations add-iam-policy-binding $ORG\_ID \\  
    \--member="serviceAccount:terraform-admin-sa@$MASTER\_PROJECT\_ID.iam.gserviceaccount.com" \\  
    \--role="roles/billing.user"

### ---

**📝 Post-Setup Summary**

| Component | Identifier |
| :---- | :---- |
| **Workload Provider** | projects/$MASTER\_PROJECT\_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider |
| **Service Account** | terraform-admin-sa@$MASTER\_PROJECT\_ID.iam.gserviceaccount.com |
| **Trust Level** | Locked to repository \== lornu-ai/lornu-ai |

### **What's next?**

With the bridge built, we can now automate the creation of your first **Enterprise Spoke**.

