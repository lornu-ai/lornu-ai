# Epic: Cloud-Native Deployment Strategy (K8s & Kustomize)

**Reference Issue:** [#80](https://github.com/lornu-ai/lornu-ai/issues/80)
**Context:** Formalize the cloud-native strategy by adopting Kustomize for GitOps-ready Kubernetes configuration management across Local, Staging, and Production environments.

---

## 1. Epics & User Stories Breakdown

### Epic 1: Kustomize Foundation & Base Infrastructure
**Goal:** Establish the core Kustomize directory structure and migrate base manifests.

*   **Story 1.1: Setup Kustomize Directory Structure**
    *   **Description:** Create the directory hierarchy `k8s/base` and `k8s/overlays`.
    *   **Acceptance Criteria:** Directory structure exists in repo.
*   **Story 1.2: Migrate Core Manifests to Base**
    *   **Description:** Refactor existing Deployment, Service, and ConfigMap YAMLs into `k8s/base/`. Ensure they are environment-agnostic.
    *   **Acceptance Criteria:** `deployment.yaml`, `service.yaml` in `k8s/base`. `kustomization.yaml` created in `base`.
*   **Story 1.3: Local Development Overlay**
    *   **Description:** Create `k8s/overlays/dev` specific for local testing (Podman/Kind).
    *   **Acceptance Criteria:** Functional `kustomize build k8s/overlays/dev` command. Includes dev-specific config (e.g., debug logging).
    *   **Task:** Update `package.json` script `dev:k8s` to use Kustomize.

### Epic 2: Staging Environment Configuration
**Goal:** Define the Staging environment configuration using Kustomize overlays.

*   **Story 2.1: Staging Overlay Implementation**
    *   **Description:** Create `k8s/overlays/staging`.
    *   **Acceptance Criteria:** Staging specific `kustomization.yaml` properly patches image tags, replicas (if different), and resource limits.
*   **Story 2.2: Secret Management Strategy**
    *   **Description:** Define how secrets (API keys) are injected in Staging (e.g., SealedSecrets or external secret store reference).
    *   **Acceptance Criteria:** Documented and implemented method for providing `STAGE_API_KEY` etc.

### Epic 3: CI/CD Integration
**Goal:** Automate the manifest generation and deployment.

*   **Story 3.1: CI/CD Kustomize Build Step**
    *   **Description:** Update GitHub Actions workflow to install Kustomize and build manifests before deployment.
    *   **Acceptance Criteria:** Workflow logs show `kustomize build` outputting valid YAML.
*   **Story 3.2: Automated Deployment to Staging**
    *   **Description:** Apply the generated Staging manifests to the target cluster (AWS EKS/ECS or similar).
    *   **Acceptance Criteria:** Successful `kubectl apply` in CI pipeline.

---

## 2. Implementation Plan

### Phase A: Setup (Week 1)
1.  Initialize `k8s/` structure.
2.  Port existing raw YAMLs to `base`.
3.  Verify local build with `kustomize build k8s/base`.

### Phase B: Development Overlay (Week 1)
1.  Create `overlays/dev`.
2.  Add `dev` specific patches (e.g. `replicas: 1`).
3.  Update local developer scripts.

### Phase C: Staging & CI (Week 2)
1.  Create `overlays/staging`.
2.  Modify `.github/workflows/deploy.yaml` (or new workflow).
3.  Test end-to-end deployment.

---

## 3. Checklist
- [ ] Base Kustomization (`k8s/base`)
- [ ] Dev Overlay (`k8s/overlays/dev`)
- [ ] Staging Overlay (`k8s/overlays/staging`)
- [ ] CI/CD Pipeline Update
- [ ] Documentation Updated (README.md)
