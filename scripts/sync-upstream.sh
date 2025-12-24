#!/bin/bash
# Sync Upstream Script
# This script pulls verified features from the lornu-ai-dev (Cloudflare Edge) repo
# and merges them into the develop branch of the main lornu-ai (Enterprise) repo.

set -e

DEV_REPO="https://github.com/lornu-ai/lornu-ai-dev.git"
DEV_BRANCH="main"
LOCAL_BRANCH="develop"

echo "🚀 Starting Upstream Sync from lornu-ai-dev..."

# 1. Ensure we are on the local develop branch
git checkout $LOCAL_BRANCH
git pull origin $LOCAL_BRANCH

# 2. Add dev remote if it doesn't exist
if ! git remote | grep -q "^dev$"; then
    echo "➕ Adding dev remote..."
    git remote add dev $DEV_REPO
fi

# 3. Fetch from dev
echo "📡 Fetching from dev..."
git fetch dev $DEV_BRANCH

# 4. Merge changes
# We use --no-ff to keep the merge history and --allow-unrelated-histories if needed (initial sync only)
echo "🔀 Merging dev/$DEV_BRANCH into $LOCAL_BRANCH..."
git merge dev/$DEV_BRANCH -m "chore: sync features from lornu-ai-dev"

echo "✅ Sync complete. Please review any conflicts and run tests before pushing."
echo "Suggested next step: bun run test && git commit"
