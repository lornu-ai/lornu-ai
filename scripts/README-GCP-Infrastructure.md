# GCP Infrastructure Management Scripts

This directory contains scripts that address [GitHub Issue #444: Legacy Cloud Infrastructure Discovery and Terraform Import](https://github.com/lornu-ai/lornu-ai/issues/444).

## 📋 Overview

These scripts implement a comprehensive solution for discovering, importing, and managing GCP infrastructure with Terraform, following the requirements outlined in the GitHub issue.

## 🛠️ Scripts

### 1. Discovery and Assessment

#### `gcp-cleanup-assessment.sh`
**Purpose:** Comprehensive assessment of existing GCP resources  
**GitHub Issue Phase:** Phase 1 - Inventory & Prioritization

```bash
# Basic usage
./scripts/gcp-cleanup-assessment.sh

# With GitHub CLI integration
gh issue view 444  # Review requirements first
./scripts/gcp-cleanup-assessment.sh
gh issue comment 444 --body "Assessment complete - see results above"
```

**Features:**
- Lists all GCP resources by category (Compute, Storage, Networking, IAM)
- Identifies resources managed by Terraform vs. unmanaged resources
- Provides import recommendations with specific commands
- Generates cleanup recommendations for unused resources

#### `gcp-discovery-terraformer.sh`
**Purpose:** Automated resource discovery using terraformer tool  
**GitHub Issue Phase:** Phase 1 - Automated Resource Discovery (Requirement 3.1)

```bash
# Install terraformer first (macOS)
brew install terraformer

# Run discovery
./scripts/gcp-discovery-terraformer.sh

# With GitHub integration
gh issue comment 444 --body "Starting automated discovery with terraformer"
./scripts/gcp-discovery-terraformer.sh
```

**Features:**
- Uses terraformer for automated HCL generation
- Prioritizes mission-critical resources (networking, IAM)
- Generates organized output structure
- Creates GitHub issue updates with discovery results
- Supports all major GCP resource types

### 2. Import and Migration

#### `terraform-import-gcp.sh`
**Purpose:** Import existing GCP resources into Terraform state  
**GitHub Issue Phase:** Phase 2 - The Import Workflow (Requirement 3.3)

```bash
# Change to terraform directory first
cd terraform/gcp

# Run import script
../../scripts/terraform-import-gcp.sh

# With GitHub integration
gh issue view 444
../../scripts/terraform-import-gcp.sh
gh pr create --title "feat: import GCP resources to Terraform" --label "infrastructure"
```

**Features:**
- Uses modern Terraform 1.5+ import blocks (idempotent imports)
- Supports `terraform plan -generate-config-out` for HCL generation
- Verifies zero-diff after import (Requirement 3.5)
- Handles multiple resource types automatically
- Provides fallback to legacy import methods

### 3. Cleanup and Maintenance

#### `gcp-cleanup.sh`
**Purpose:** Safe removal of unused GCP resources  
**GitHub Issue Phase:** Ongoing maintenance

```bash
# Dry run mode (default - safe)
DRY_RUN=true ./scripts/gcp-cleanup.sh

# Actual cleanup (after review)
DRY_RUN=false ./scripts/gcp-cleanup.sh

# With GitHub integration
gh issue comment 444 --body "Starting cleanup process"
./scripts/gcp-cleanup.sh
```

**Features:**
- Dry run mode by default (safe)
- Interactive confirmation for each deletion
- Preserves Terraform-managed resources
- Checks for resource dependencies before deletion
- Provides detailed logging and audit trail

#### `gcp-drift-detection.sh`
**Purpose:** Continuous monitoring for configuration drift  
**GitHub Issue Phase:** Phase 3 - Continuous Drift Detection

```bash
# Manual drift check
./scripts/gcp-drift-detection.sh

# In GitHub Actions (automated)
gh workflow run drift-detection.yml
```

**Features:**
- Uses `terraform plan -detailed-exitcode` for drift detection
- Configurable alert thresholds
- Automatic GitHub issue creation for drift alerts
- Detailed drift reports with remediation steps
- CI/CD integration with proper exit codes

## 🔧 Prerequisites

### Required Tools
```bash
# Core tools
gcloud --version      # Google Cloud SDK
terraform --version   # Terraform 1.5+
gh --version          # GitHub CLI (optional but recommended)

# Discovery tools
terraformer version   # For automated resource discovery
```

### Required Authentication
```bash
# GCP Authentication
gcloud auth login
gcloud auth application-default login
gcloud config set project gcp-lornu-ai

# GitHub Authentication (optional)
gh auth login
```

### Environment Variables
```bash
# Required
export GCP_PROJECT_ID="gcp-lornu-ai"
export GCP_REGION="us-central1"

# Optional
export GKE_CLUSTER_NAME="lornu-ai-gke"
export DRY_RUN="true"  # For cleanup script
export DRIFT_ALERT_THRESHOLD="1"  # For drift detection
```

## 📊 Workflow

### Phase 1: Discovery and Assessment
```bash
# 1. Assess existing infrastructure
./scripts/gcp-cleanup-assessment.sh

# 2. Automated discovery with terraformer
./scripts/gcp-discovery-terraformer.sh

# 3. Review generated HCL files
ls -la terraform-discovered/
```

### Phase 2: Import and Terraform Migration
```bash
# 4. Import resources using modern import blocks
cd terraform/gcp
../../scripts/terraform-import-gcp.sh

# 5. Verify zero-diff
terraform plan

# 6. Clean up unused resources
../../scripts/gcp-cleanup.sh
```

### Phase 3: Continuous Monitoring
```bash
# 7. Set up drift detection (in CI/CD)
./scripts/gcp-drift-detection.sh

# 8. Schedule daily runs in GitHub Actions
# See .github/workflows/drift-detection.yml
```

## 🔗 GitHub Integration

All scripts support GitHub CLI integration for seamless issue tracking:

```bash
# View the original issue
gh issue view 444

# Run any script with GitHub updates
./scripts/gcp-cleanup-assessment.sh
gh issue comment 444 --body "Assessment completed - see logs for details"

# Create PRs for infrastructure changes
gh pr create --title "feat: import GCP infrastructure" \
  --body "Addresses #444 - imports existing GCP resources to Terraform" \
  --label "infrastructure"
```

## 📚 Documentation References

- **GitHub Issue:** [#444 Legacy Cloud Infrastructure Discovery and Terraform Import](https://github.com/lornu-ai/lornu-ai/issues/444)
- **Terraform Documentation:** [Import Blocks](https://developer.hashicorp.com/terraform/language/import)
- **Terraformer GitHub:** [GoogleCloudPlatform/terraformer](https://github.com/GoogleCloudPlatform/terraformer)
- **GCP Best Practices:** [Infrastructure as Code](https://cloud.google.com/docs/terraform/best-practices-for-terraform)

## 🚨 Safety Notes

1. **Always run in dry-run mode first** - All destructive scripts default to dry-run
2. **Review generated HCL** - Terraformer output needs manual review and cleanup  
3. **Backup important data** - Ensure backups before deleting resources
4. **Test in staging first** - Validate the process in non-production environments
5. **Monitor for drift** - Set up continuous monitoring after import

## 🏷️ Success Criteria (from Issue #444)

- [ ] 90% of production infrastructure managed by Terraform
- [ ] Zero manual changes permitted in production (Console access set to Read-Only)
- [ ] Successful `terraform destroy` and `terraform apply` can recreate staging environment
- [ ] All GCP resources tagged with `ManagedBy: Terraform`

## 🆘 Troubleshooting

### Common Issues

**Terraformer fails to install:**
```bash
# macOS
brew install terraformer

# Manual installation
# See: https://github.com/GoogleCloudPlatform/terraformer#installation
```

**Import fails with permissions error:**
```bash
# Check GCP authentication
gcloud auth list
gcloud auth application-default login

# Verify project access
gcloud projects describe gcp-lornu-ai
```

**Drift detection false positives:**
```bash
# Adjust alert threshold
export DRIFT_ALERT_THRESHOLD=5

# Or disable alerts temporarily
export DRIFT_ALERT_THRESHOLD=999
```

### Getting Help

1. **Check script logs** - All scripts provide detailed logging
2. **Review GitHub issue** - See #444 for requirements and discussion
3. **Test with dry-run** - Use dry-run mode to preview changes
4. **Check documentation** - Review Terraform and GCP documentation

---

**Last Updated:** 2025-12-26  
**Maintainer:** Cloud Architecture / DevOps Team  
**GitHub Issue:** [#444](https://github.com/lornu-ai/lornu-ai/issues/444)