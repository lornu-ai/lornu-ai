# Terraform Automation Setup

This guide explains the automated Terraform formatting and validation setup for the Lornu AI repository.

## Overview

We have **two layers** of Terraform automation:

1. **Pre-commit Hooks** - Run locally before each commit
2. **GitHub Actions** - Run on every PR and push to main/develop

## Pre-commit Hooks (Local)

### Setup

Install pre-commit (if not already installed):

```bash
# macOS
brew install pre-commit

# Or via pip
pip install pre-commit
```

Install the hooks:

```bash
pre-commit install
```

### What It Does

When you commit Terraform files (`.tf`), pre-commit automatically:

1. **Formats** files with `terraform fmt`
2. **Validates** syntax with `terraform validate`
3. **Lints** with `tflint` (checks for best practices)
4. **Security scans** with `tfsec` (detects security issues)

### Manual Run

Test all files (not just staged):

```bash
pre-commit run --all-files
```

Run only Terraform hooks:

```bash
pre-commit run terraform_fmt --all-files
pre-commit run terraform_validate --all-files
```

### Bypassing (Not Recommended)

If you need to bypass pre-commit (emergency only):

```bash
git commit --no-verify -m "emergency fix"
```

**Note**: The GitHub Action will still catch formatting issues.

## GitHub Actions (CI/CD)

### Workflow: `terraform-lint.yml`

**Triggers:**
- Pull requests with Terraform changes
- Pushes to `main` or `develop` branches

**What It Does:**

1. **Format Check** (`terraform-fmt` job)
   - Checks if files are formatted correctly
   - Auto-fixes and comments on PR if issues found
   - Runs for both `staging` and `production` directories

2. **Validation** (`terraform-validate` job)
   - Validates Terraform syntax
   - Runs `terraform init -backend=false` (no state required)
   - Runs for both `staging` and `production` directories

3. **Summary** (`terraform-summary` job)
   - Reports overall status
   - Fails PR if any checks fail

### Viewing Results

1. Go to: `https://github.com/lornu-ai/lornu-ai/actions`
2. Find: **"Terraform Lint & Validate"**
3. Click on the workflow run
4. Review each job's output

### Auto-fix Comments

If formatting issues are detected, the workflow will:
- Comment on your PR with fix instructions
- Show which directory has issues
- Provide copy-paste commands to fix

## Manual Commands

### Format All Terraform Files

```bash
# From repo root
terraform fmt -recursive terraform/

# Or specific directory
terraform fmt -recursive terraform/aws/staging
terraform fmt -recursive terraform/aws/production
```

### Validate All Terraform Files

```bash
# Staging
cd terraform/aws/staging
terraform init -backend=false
terraform validate

# Production
cd terraform/aws/production
terraform init -backend=false
terraform validate
```

## Troubleshooting

### Pre-commit Not Running

**Issue**: Pre-commit hooks don't run on commit

**Solution**:
```bash
# Reinstall hooks
pre-commit uninstall
pre-commit install

# Test manually
pre-commit run --all-files
```

### GitHub Action Fails

**Issue**: `terraform validate` fails in CI

**Common Causes:**
1. **Missing variables**: Check if all required variables are set
2. **Provider version mismatch**: Update `required_providers` block
3. **Syntax errors**: Run `terraform fmt` and `terraform validate` locally first

**Solution**:
```bash
# Run locally first
cd terraform/aws/staging
terraform init -backend=false
terraform validate

# Fix any errors, then push
```

### Formatting Issues in PR

**Issue**: GitHub Action comments about formatting

**Solution**:
```bash
# Auto-fix
terraform fmt -recursive terraform/

# Commit and push
git add terraform/
git commit -m "fix: format Terraform files"
git push
```

## Best Practices

1. **Always run pre-commit locally** before pushing
2. **Fix formatting issues** before opening PR
3. **Review GitHub Action results** on every PR
4. **Don't bypass hooks** unless absolutely necessary

## Configuration Files

- **Pre-commit**: `.pre-commit-config.yaml`
- **GitHub Action**: `.github/workflows/terraform-lint.yml`

## Hooks Included

### Pre-commit Terraform Hooks

- `terraform_fmt` - Auto-format files
- `terraform_validate` - Validate syntax
- `terraform_tflint` - Lint for best practices
- `terraform_tfsec` - Security scanning

### GitHub Action Jobs

- `terraform-fmt` - Format check with auto-fix suggestions
- `terraform-validate` - Syntax validation
- `terraform-summary` - Overall status report

---

**See Also:**
- [AGENTS.md](../AGENTS.md) - Terraform hygiene requirements
- [.ai/RULES.md](../.ai/RULES.md) - Project rules
