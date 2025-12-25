# Plan A — Migration Notes

## Objective
Retire legacy ECS/Cloudflare references and align all infrastructure and documentation to the **Plan A** single-cluster, multi-namespace model.

## Scope
- Documentation realignment to `kubernetes/base/` and `kubernetes/overlays/`.
- Namespace standardization: `lornu-dev`, `lornu-staging`, `lornu-prod`.
- Protective Metadata enforcement on all Kubernetes resources.

## Checklist
1. Remove ECS and Cloudflare references from core docs.
2. Ensure overlays contain `namespace.yaml` with required labels.
3. Validate all doc paths and commands against the `kustomize` branch.
