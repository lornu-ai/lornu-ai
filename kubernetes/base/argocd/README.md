# ArgoCD GitOps Setup

ArgoCD provides GitOps capabilities for the Lornu platform, moving us from a "Push" model (GitHub Actions forcing changes) to a "Pull" model (the cluster constantly syncing itself).

## Why ArgoCD?

- **Beautiful UI**: Visualizes relationships between XAgentEnvironment and AWS/GCP resources
- **GitOps Native**: Pull-based sync from Git repository
- **Self-Healing**: Automatically reverts manual changes
- **Diff View**: See exactly what changed when resources drift
- **Dependency Logic**: Sync order management (e.g., wait for GCP Provider to be healthy)

## Architecture

```
Git Repository (GitHub)
    ↓
ArgoCD (watches Git)
    ↓
Crossplane (sees new XRDs/Compositions)
    ↓
AWS/GCP Infrastructure (provisioned)
```

## Installation

ArgoCD is installed via Kustomize:

```bash
kubectl apply -k kubernetes/base/argocd/
```

This installs:
- ArgoCD server, controller, and UI
- Application CRD and related resources
- Default project configuration

## App-of-Apps Pattern

The `app-of-apps.yaml` file defines the root Application that tells ArgoCD to watch our infrastructure folder. This creates the GitOps "loop":

1. Python provisioner commits YAML files to `workspaces/` directory
2. ArgoCD notices the new file and pulls it into the cluster
3. Crossplane sees the new object and builds the AWS/GCP infrastructure

## Accessing ArgoCD UI

After installation, get the initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Port-forward to access the UI:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then visit: https://localhost:8080

Default username: `admin`

## Python Provisioner Strategy

With GitOps, the Python provisioner no longer talks to the K8s API directly. Instead, it commits YAML files to Git:

```python
# OLD WAY (Push model)
custom_api.create_cluster_custom_object(...)

# NEW WAY (GitOps/Pull model)
git_repo.index.add([new_agent_yaml])
git_repo.index.commit("Add agent X")
git_repo.remote().push()
```

## Workspaces Directory

The `workspaces/` directory contains agent environment configurations:

- Files are committed here by the Python provisioner
- ArgoCD watches this directory
- Crossplane provisions infrastructure based on the YAML files

See `workspaces/README.md` for more details.

## Benefits

1. **Visibility**: Tree-map visualization of your agent infrastructure
2. **Drift Detection**: Yellow "Out of Sync" status when manual changes occur
3. **Diff View**: See exactly what changed before Crossplane forces it back
4. **Dependency Management**: Sync order control (e.g., wait for providers)
5. **Audit Trail**: All changes tracked in Git history

## Configuration

### Sync Policy

The App-of-Apps uses:
- `automated.prune: true` - Delete resources removed from Git
- `automated.selfHeal: true` - Automatically revert manual changes
- `syncOptions.CreateNamespace: true` - Auto-create namespaces

### Project

Default project is used. For multi-tenancy, you can create separate ArgoCD projects.

## Troubleshooting

### ArgoCD not syncing

Check the Application status:
```bash
kubectl get application lornu-platform -n argocd
kubectl describe application lornu-platform -n argocd
```

### Resources out of sync

View the diff in ArgoCD UI, or:
```bash
argocd app diff lornu-platform
```

### Manual sync

```bash
argocd app sync lornu-platform
```

## References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [App-of-Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [GitOps Principles](https://www.gitops.tech/)

