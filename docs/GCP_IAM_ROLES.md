# Required IAM Roles for GCP Infrastructure Service Account

## Minimum Required Roles for GKE + Firestore + IAM

The service account used by Terraform (and GitHub Actions) needs the following roles:

### 1. **Service Usage Admin** (CRITICAL)
- **Role**: `roles/serviceusage.serviceUsageAdmin`
- **Needed for**: Enabling Google Cloud APIs via Terraform
- **Grants**: Ability to enable/disable APIs in the project
- **Why**: Terraform auto-enables required APIs (IAM, GKE, Firestore, etc.)

### 2. **Kubernetes Engine Admin**
- **Role**: `roles/container.admin`
- **Needed for**: Creating and managing GKE clusters
- **Grants**: Full control over GKE clusters, node pools, and cluster resources

### 2. **Compute Network Admin**
- **Role**: `roles/compute.networkAdmin`
- **Needed for**: Creating VPC network and subnets for GKE
- **Grants**: Full control over VPC networks, subnets, and firewall rules

### 3. **Cloud Datastore Owner**
- **Role**: `roles/datastore.owner`
- **Needed for**: Creating and managing Firestore database
- **Alternative**: `roles/firebase.admin` if using Firebase

### 4. **Service Account Admin**
- **Role**: `roles/iam.serviceAccountAdmin`
- **Needed for**: Creating the backend service account (`lornu-backend`)
- **Grants**: Create/delete/manage service accounts

### 5. **Project IAM Admin**
- **Role**: `roles/resourcemanager.projectIamAdmin`
- **Needed for**: Granting roles to service accounts (Vertex AI, Firestore, Workload Identity)
- **Grants**: Modify IAM policies on the project

---

## Grant Commands (All Required Roles)

```bash
PROJECT_ID="your-project-id"
SA_EMAIL="your-sa@your-project.iam.gserviceaccount.com"

# Grant Service Usage Admin (MUST BE FIRST - enables APIs)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/serviceusage.serviceUsageAdmin"

# Grant Kubernetes Engine Admin
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/container.admin"

# Grant Compute Network Admin
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/compute.networkAdmin"

# Grant Cloud Datastore Owner
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/datastore.owner"

# Grant Service Account Admin
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountAdmin"

# Grant Project IAM Admin
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/resourcemanager.projectIamAdmin"
```

---

## One-Liner (All Roles)

```bash
PROJECT_ID="your-project-id"
SA_EMAIL="your-sa@your-project.iam.gserviceaccount.com"

for role in roles/serviceusage.serviceUsageAdmin roles/container.admin roles/compute.networkAdmin roles/datastore.owner roles/iam.serviceAccountAdmin roles/resourcemanager.projectIamAdmin; do
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="$role"
done
```

---

## Summary Table

| Role | Purpose | Required |
|------|---------|----------|
| `roles/serviceusage.serviceUsageAdmin` | Enable/disable APIs | ✅ Yes (FIRST!) |
| `roles/container.admin` | Manage GKE clusters | ✅ Yes |
| `roles/compute.networkAdmin` | Manage VPC/subnets | ✅ Yes |
| `roles/datastore.owner` | Manage Firestore | ✅ Yes |
| `roles/iam.serviceAccountAdmin` | Create service accounts | ✅ Yes |
| `roles/resourcemanager.projectIamAdmin` | Grant IAM roles | ✅ Yes |

---

## Alternative: Use Predefined Role

If your organization policy allows, you can use:

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/editor"
```

**Note**: `roles/editor` includes all the above permissions but is less restrictive. Use the granular roles above for better security posture.

---

## Verification

Check that roles are applied:

```bash
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:${SA_EMAIL}" \
  --format="table(bindings.role)"
```

Expected output should show all 5 roles listed above.

---

## Security Notes

- ✅ **Follow least privilege principle**: Only grant the roles listed above
- ✅ **Avoid `roles/owner`**: Too permissive for CI/CD
- ⚠️ **`roles/editor`** is acceptable but less secure than granular roles
- 🔐 **Rotate service account keys every 90 days**
