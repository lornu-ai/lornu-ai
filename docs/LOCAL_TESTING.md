# Local Kubernetes Testing (minikube + podman)

Fast loop for running the app locally on Kubernetes without touching AWS.

## Prerequisites
- macOS with Homebrew
- Tools: `minikube`, `kubectl`, `kustomize`, `podman` (preferred) or `docker`
- Repo root: `lornu-ai`

## Quick start
1) Start cluster and build image inside it:
   ```bash
   ./scripts/local-k8s-setup.sh
   ```
2) Deploy manifests to minikube:
   ```bash
   ./scripts/local-k8s-deploy.sh
   ```
3) Run smoke tests (health + frontend):
   ```bash
   ./scripts/local-k8s-test.sh
   ```
4) Access the app:
   ```bash
   kubectl port-forward svc/lornu-ai 8080:8080
   open http://localhost:8080
   ```
5) Cleanup when done:
   ```bash
   ./scripts/local-k8s-cleanup.sh
   ```

## Notes
- The scripts prefer Podman; Docker is used if Podman is absent.
- Images are built inside the minikube runtime (`minikube docker-env`), so no registry push is required.
- Addons enabled by setup: registry, ingress, metrics-server.
- To expose LoadBalancer services locally: `minikube tunnel` (requires sudo on some systems).
- For a UI, run `minikube dashboard` in another terminal.

## Troubleshooting
- Stale images: rerun setup or `./scripts/local-k8s-cleanup.sh` and rebuild.
- Pods stuck Pending: check `kubectl describe pod ...` and ensure minikube has enough CPU/RAM.
- Network issues on podman: restart minikube with `minikube delete` then rerun setup.
