#!/bin/bash
# Rebase a PR branch on the new consolidated base
# Usage: ./scripts/rebase-pr-branch.sh <branch-name> [base-branch]

BRANCH_NAME="$1"
BASE_BRANCH="${2:-kustomize}"

if [ -z "$BRANCH_NAME" ]; then
    echo "❌ Error: Branch name required"
    echo "Usage: $0 <branch-name> [base-branch]"
    exit 1
fi

set -e

echo "🔄 Rebasing $BRANCH_NAME on $BASE_BRANCH..."

# Fetch latest
git fetch origin

# Checkout the branch
git checkout "$BRANCH_NAME" 2>/dev/null || {
    echo "❌ Branch $BRANCH_NAME not found locally"
    echo "   Creating from remote..."
    git checkout -b "$BRANCH_NAME" "origin/$BRANCH_NAME"
}

# Rebase
echo "📦 Rebasing on origin/$BASE_BRANCH..."
git rebase "origin/$BASE_BRANCH" || {
    echo "⚠️  Rebase conflicts detected. Resolve manually, then:"
    echo "   git add ."
    echo "   git rebase --continue"
    echo "   git push origin $BRANCH_NAME --force-with-lease"
    exit 1
}

# Force push with lease (safer than --force)
echo "📤 Pushing rebased branch..."
git push origin "$BRANCH_NAME" --force-with-lease

echo "✅ Rebase complete! PR should update automatically."
