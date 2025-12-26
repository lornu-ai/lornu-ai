#!/bin/bash
# Recreate a PR that was targeting gcp-develop on the new consolidated base
# Usage: ./scripts/recreate-pr-from-gcp-develop.sh <old-branch> <new-branch-name> <pr-title> [base-branch]

OLD_BRANCH="$1"
NEW_BRANCH="$2"
PR_TITLE="$3"
BASE_BRANCH="${4:-kustomize}"

if [ -z "$OLD_BRANCH" ] || [ -z "$NEW_BRANCH" ] || [ -z "$PR_TITLE" ]; then
    echo "❌ Error: Missing required arguments"
    echo "Usage: $0 <old-branch> <new-branch-name> <pr-title> [base-branch]"
    exit 1
fi

set -e

echo "🔄 Recreating PR from $OLD_BRANCH as $NEW_BRANCH..."

# Fetch latest
git fetch origin

# Create new branch from base
echo "🌿 Creating new branch $NEW_BRANCH from $BASE_BRANCH..."
git checkout -b "$NEW_BRANCH" "origin/$BASE_BRANCH"

# Get commits from old branch
echo "📦 Getting commits from $OLD_BRANCH..."
COMMITS=$(git log "origin/$BASE_BRANCH".."origin/$OLD_BRANCH" --oneline --reverse | awk '{print $1}')

if [ -z "$COMMITS" ]; then
    echo "⚠️  No unique commits found in $OLD_BRANCH"
    echo "   The changes may already be in $BASE_BRANCH"
    exit 1
fi

# Cherry-pick commits
echo "🍒 Cherry-picking commits..."
for commit in $COMMITS; do
    echo "   Picking: $commit"
    git cherry-pick "$commit" || {
        echo "⚠️  Conflict in commit $commit. Resolve manually, then:"
        echo "   git add ."
        echo "   git cherry-pick --continue"
        exit 1
    }
done

# Push new branch
echo "📤 Pushing new branch..."
git push origin "$NEW_BRANCH"

# Create PR
echo "📝 Creating new PR..."
gh pr create \
    --base "$BASE_BRANCH" \
    --head "$NEW_BRANCH" \
    --title "$PR_TITLE" \
    --body "Recreated from $OLD_BRANCH after PR #347 consolidation. Original changes rebased on new base branch."

echo "✅ PR recreated successfully!"
echo "   Remember to close the old PR if it exists."
