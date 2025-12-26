#!/bin/bash
# Post-Merge Cleanup Script for PR #347
# Usage: ./scripts/post-merge-cleanup.sh [kustomize|main]

set -e

TARGET_BRANCH="${1:-kustomize}"
echo "🧹 Starting post-merge cleanup for branch: $TARGET_BRANCH"

# Fetch latest
echo "📥 Fetching latest from remote..."
git fetch origin

# Checkout target branch
echo "🔀 Checking out $TARGET_BRANCH..."
git checkout "$TARGET_BRANCH" 2>/dev/null || git checkout -b "$TARGET_BRANCH" "origin/$TARGET_BRANCH"

# Reset to remote state
echo "🔄 Resetting to remote state..."
git reset --hard "origin/$TARGET_BRANCH"

# Clean untracked files
echo "🧽 Cleaning untracked files..."
git clean -fd

# Show status
echo "✅ Cleanup complete!"
echo ""
echo "Current branch: $(git branch --show-current)"
echo "Latest commit: $(git log -1 --oneline)"
echo ""
echo "📋 Next steps:"
echo "  1. Review open PRs that need rebase/recreation"
echo "  2. Rebase PR branches: git checkout <branch> && git rebase origin/$TARGET_BRANCH"
echo "  3. Or recreate PRs from gcp-develop targeting branches"
