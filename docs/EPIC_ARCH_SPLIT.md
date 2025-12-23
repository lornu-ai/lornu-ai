# Epic: Architecture Split - Decoupling Dev (Cloudflare) from Enterprise (AWS/GCP)

**Epic ID:** ARCH-SPLIT-001
**Related Issue:** #127

## Executive Summary
This epic outlines the strategy to decouple the "Dev" environment (hosted on Cloudflare Workers for speed/agility) from the "Enterprise" environment (hosted on AWS ECS/Fargate or GKE for compliance and security). This involves splitting the repository structure, identifying a clear migration path, and ensuring ensuring strict synchronization between the two environments.

## 1. Objectives
*   **Decouple Environments:** Separate the fast-iteration Dev environment from the stable, secure Enterprise environment.
*   **Streamline Infrastructure:** Simplify the main repo to be AWS/GCP native, removing Cloudflare artifacts.
*   **Maintain Synchronization:** Establish a protocol to ensure feature parity and code consistency between the Dev (fork) and Enterprise (main) repos.
*   **Enhance Security:** Ensure Enterprise infrastructure is managed purely via Terraform without interference from Dev-centric configs.

## 2. Architecture Overview

### Current State (Monorepo)
*   Mixed `wrangler.toml` (Cloudflare) and `terraform/` (AWS) in the same repo.
*   Potential for state conflict and complexity in CI/CD pipelines.

### Target State (Split)
1.  **Main Repo (`lornu-ai`)**:
    *   **Focus**: Enterprise Staging/Production.
    *   **Infrastructure**: AWS ECS Fargate / GKE via Terraform.
    *   **CI/CD**: GitHub Actions -> AWS ECR -> ECS.
    *   **Artifacts**: Docker images only. No `wrangler.toml`.

2.  **Dev Repo (`lornu-ai-dev` - Fork)**:
    *   **Focus**: Rapid Prototyping / Dev Environment.
    *   **Infrastructure**: Cloudflare Workers (Edge).
    *   **CI/CD**: GitHub Actions -> Cloudflare Workers.
    *   **Artifacts**: `wrangler.toml`, Worker scripts.

## 3. Implementation Plan

### Phase 1: Investigation & Validation
*   **Goal**: Ensure the split won't break critical workflows.
*   **Tasks**:
    *   [ ] **Build Scope Validation**: Verify if Cloudflare builds can be restricted to `apps/web` to avoid repo-wide scanning.
    *   [ ] **State Auditing**: Ensure no existing Terraform state relies on Cloudflare resources.

### Phase 2: Execution (The Fork & Split)
*   **Goal**: Perform the physical separation of code and config.
*   **Tasks**:
    *   [ ] **Create Fork**: Initialize `lornu-ai-dev` as a fork of `stevei101/lornuai-inc`.
    *   [ ] **Link Dev Dashboard**: Connect `lornu-ai-dev:main` to Cloudflare Dashboard.
    *   [ ] **Prune Main Repo**: Remove `wrangler.toml` and `wrangler` dependencies from `lornu-ai`.
    *   [ ] **Harden CI/CD**: Finalize AWS ECS deployment workflows in `lornu-ai`.

### Phase 3: Synchronization & Documentation
*   **Goal**: Ensure ongoing consistency and clarity.
*   **Tasks**:
    *   [ ] **Docs Update**: Update `README.md` and GTM strategy to reflect the split.
    *   [ ] **Sync Protocol**: Establish the "Upstream Sync" workflow (weekly merge from Dev to Main).
    *   [ ] **Schema Alignment**: Enforce shared Protobuf/JSON schemas for Agent communication (A2A).

## 4. User Stories / Tasks

| ID | Title | Description | Est. Effort |
| :--- | :--- | :--- | :--- |
| **STORY-1** | Create `lornu-ai-dev` Repo | Fork the repository and configure it for Cloudflare-only deployment. Establish it as the "Dev" upstream. | Low |
| **STORY-2** | Prune Cloudflare from Main | Remove `wrangler.toml`, `worker.ts` (if unused in container), and Cloudflare dependencies from the main `lornu-ai` repo. | Medium |
| **STORY-3** | Finalize AWS CI/CD | Ensure the `terraform-aws.yml` workflow correctly builds Docker images and pushes to ECR on PRs. | High |
| **STORY-4** | Establish Sync Workflow | Document and script the process for merging `lornu-ai-dev` features back into `lornu-ai` without re-introducing Cloudflare config. | Medium |
| **STORY-5** | Update Project Docs | Update root `README.md` and `docs/` to clearly explain the Dev vs. Enterprise distinction. | Low |

## 5. Risk Management
*   **Risk**: Feature drift between Dev and Staging.
*   **Mitigation**: Weekly scheduled syncs; automated schema validation tests in CI.
*   **Risk**: Complexity in managing two repos.
*   **Mitigation**: Clear "Upstream -> Downstream" flow; keeping shared logic (backend) identical.
