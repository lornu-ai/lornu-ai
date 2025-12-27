# Instructions for Promoting `gcloud-oidc` to `main`

This guide provides the `git` commands to rename the `main` branch to `old-main` and then promote the `gcloud-oidc` branch to become the new `main`.

**Important:** Before you begin, ensure you have the latest changes from the remote repository by running `git fetch --all` and `git pull --all`.

### Step 1: Rename the local `main` branch

```bash
git branch -m main old-main
```

### Step 2: Rename the local `gcloud-oidc` branch to `main`

```bash
git branch -m gcloud-oidc main
```

### Step 3: Push the new `main` branch to the remote

This command pushes your new local `main` branch to the remote repository and sets it to track the remote `main` branch.

```bash
git push -u origin main
```

### Step 4: Push the `old-main` branch to the remote

This archives the old `main` branch on the remote.

```bash
git push -u origin old-main
```

### Step 5: Delete the old `main` branch from the remote

**Warning:** This is a destructive action. The recommended way to do this is through the GitHub repository settings. You will need to:
1.  Change the default branch to your new `main` branch.
2.  Delete the old `main` branch.

Attempting to delete the default branch directly from the command line is often protected.

### Step 6: Delete the old `gcloud-oidc` branch from the remote

Now that `gcloud-oidc` has been renamed to `main` and pushed, you can delete the old `gcloud-oidc` branch from the remote.

```bash
git push origin --delete gcloud-oidc
```

After completing these steps, the `gcloud-oidc` branch will be the new `main`, and your workflow will trigger accordingly.
