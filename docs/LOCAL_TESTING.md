# Local Kubernetes Testing (k3s via k3d + podman)

Fast loop for running the app locally on Kubernetes without touching AWS.

## Prerequisites
- macOS with Homebrew
- Tools: `k3d`, `kubectl`, `kustomize`, `podman` (preferred) or `docker`
- Repo root: `lornu-ai`

## Quick start
1) Start cluster and build image + push to registry:
   ```bash
   ./scripts/local-k8s-setup.sh
   ```
2) Deploy manifests to k3d:
   ```bash
   ./scripts/local-k8s-deploy.sh
   ```
3) Run smoke tests (health + frontend):
   ```bash
   ./scripts/local-k8s-test.sh
   ```
4) Access the app:
   ```bash
   kubectl port-forward svc/dev-lornu-ai 8080:80
   open http://localhost:8080
   ```
5) Cleanup when done:
   ```bash
   ./scripts/local-k8s-cleanup.sh
   ```

## Notes
- The scripts prefer Podman; Docker is used if Podman is absent.
- Images are built locally and pushed to a k3d registry at `lornu-registry.localhost:5000`.
- The k3d cluster name is `lornu-dev` and the kubectl context is `k3d-lornu-dev`.

## Troubleshooting
- Stale images: rerun setup or `./scripts/local-k8s-cleanup.sh` and rebuild.
- Pods stuck Pending: check `kubectl describe pod ...` and ensure the k3d cluster has enough CPU/RAM.
- Network issues on podman: delete the k3d cluster (`./scripts/local-k8s-cleanup.sh`) then rerun setup.
