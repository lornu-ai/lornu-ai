# PR #347 Post-Merge Cleanup & PR Recreation Plan

**Status:** Pre-Merge Preparation  
**Date:** 2025-12-26  
**PR:** #347 - Unified Multi-Cloud Branch Consolidation

## Overview

After merging PR #347, we'll need to:
1. Get a clean local repository state
2. Rename `kustomize` → `main` (if that's the plan)
3. Re-open/rebase existing PRs that target the old branch structure
4. Close superseded PRs

## Current Open PRs Status

### PRs Targeting `kustomize` (will need rebase after #347 merge):
- **#340**: `feat/issue-336-repo-metadata` → `kustomize` - **May be superseded by #347**
- **#341**: `fix/kustomize-react-chunk` → `kustomize` - **Needs rebase**
- **#331**: `feat/remove-cloudflare-workers` → `kustomize` - **Needs rebase**

### PRs Targeting `gcp-develop` (will need recreation after #347 merge):
- **#342**: `fix-pr-339-bugs` → `gcp-develop` - **Needs recreation on new base**
- **#339**: `feat/github-actions-synthetic-monitoring` → `gcp-develop` - **Needs recreation on new base**

## Post-Merge Steps

### Step 1: Clean Local Repository

After PR #347 is merged, get a clean local state:

```bash
# Fetch latest from remote
git fetch origin

# If kustomize becomes main:
git checkout kustomize
git pull origin kustomize

# Or if you want to start fresh:
git checkout -b fresh-start origin/kustomize

# Clean up any uncommitted changes
git reset --hard origin/kustomize
git clean -fd
```

### Step 2: Branch Rename (if applicable)

If `kustomize` should become `main`:

```bash
# On GitHub (via web UI or CLI):
gh api repos/:owner/:repo --method PATCH -f default_branch=main

# Or rename locally and push:
git branch -m kustomize main
git push origin main
git push origin --delete kustomize
```

### Step 3: Recreate/Rebase PRs

#### For PRs targeting `kustomize` (now `main` or new `kustomize`):

**PR #341 - React Chunk Fix:**
```bash
# Checkout the branch
git checkout fix/kustomize-react-chunk

# Rebase on new base
git rebase origin/kustomize  # or origin/main if renamed

# Force push (will update PR automatically)
git push origin fix/kustomize-react-chunk --force-with-lease
```

**PR #331 - Remove Cloudflare Workers:**
```bash
git checkout feat/remove-cloudflare-workers
git rebase origin/kustomize  # or origin/main
git push origin feat/remove-cloudflare-workers --force-with-lease
```

**PR #340 - Repo Metadata:**
```bash
# Check if superseded by #347 first
git checkout feat/issue-336-repo-metadata
git rebase origin/kustomize
# Review conflicts - may need to close if fully superseded
git push origin feat/issue-336-repo-metadata --force-with-lease
```

#### For PRs targeting `gcp-develop` (need recreation):

**PR #342 - Fix Synthetic Monitoring Bugs:**
```bash
# Create new branch from updated base
git checkout -b fix-pr-339-bugs-v2 origin/kustomize  # or origin/main

# Cherry-pick commits from old branch
git cherry-pick <commit-hash-1> <commit-hash-2>  # from fix-pr-339-bugs-712374708476861722

# Or manually recreate changes
# Then push and create new PR
git push origin fix-pr-339-bugs-v2

# Close old PR #342, open new one
gh pr create --base kustomize --head fix-pr-339-bugs-v2 --title "Fix bugs in synthetic monitoring PR #339" --body "Rebased on consolidated branch"
gh pr close 342
```

**PR #339 - Synthetic Monitoring:**
```bash
# Similar process
git checkout -b feat/github-actions-synthetic-monitoring-v2 origin/kustomize
# Cherry-pick or recreate
git push origin feat/github-actions-synthetic-monitoring-v2
gh pr create --base kustomize --head feat/github-actions-synthetic-monitoring-v2 --title "feat: GitHub Actions Synthetic Monitoring (Issue #107)" --body "Rebased on consolidated branch"
gh pr close 339
```

### Step 4: Close Superseded PRs

After reviewing, close PRs that are fully superseded by #347:
```bash
gh pr close 340  # If repo metadata is included in #347
```

## Backup Branches Created

We've created backup branches (timestamp: 20251226-06124X):
- `backup/kustomize-20251226-061242`
- `backup/main-20251226-061243`
- `backup/develop-20251226-061243`
- `backup/gcp-develop-20251226-061244`

These can be used to restore if needed.

## Verification Checklist

After cleanup:
- [ ] Local repo is clean and matches remote `kustomize` (or `main`)
- [ ] All PRs have been rebased/recreated
- [ ] Superseded PRs are closed
- [ ] New PRs are opened with correct base branch
- [ ] CI/CD workflows are working on new structure
- [ ] Terraform Cloud workspaces are updated (if needed)

## Quick Reference Commands

```bash
# Get clean state
git fetch origin
git checkout kustomize  # or main
git reset --hard origin/kustomize
git clean -fd

# Rebase a PR branch
git checkout <branch-name>
git rebase origin/kustomize
git push origin <branch-name> --force-with-lease

# Create new PR from old branch
git checkout -b <new-branch-name> origin/kustomize
git cherry-pick <commit-range>
git push origin <new-branch-name>
gh pr create --base kustomize --head <new-branch-name> --title "<title>" --body "<body>"
```

## Notes

- Use `--force-with-lease` instead of `--force` for safer force pushes
- Always verify PRs after rebase/recreation
- Keep backup branches until all PRs are successfully migrated
- Update any documentation that references old branch names

