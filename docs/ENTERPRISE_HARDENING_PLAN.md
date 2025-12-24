# Implementation Plan: Enterprise Hardening & AWS Deployment

**Status:** Implementation In-Progress
**Epic:** #127 (Architecture Split)

## 1. Overview
This plan tracks the transformation of the main `lornu-ai` repository into an "Enterprise Grade" containerized stack, primarily targeting AWS (ECS/Fargate) and GCP. This repository will act as the downstream recipient of verified features from `lornu-ai-dev`.

## 2. Infrastructure (AWS Staging)
- [x] **VPC & Networking**: Private/Public subnets, NAT Gateway, security groups.
- [x] **Compute**: ECS Fargate Cluster and Service definitions.
- [x] **Load Balancing**: Application Load Balancer with HTTPS listener (Redirect 80 -> 443).
- [x] **Image Registry**: Amazon ECR repository `lornu-ai-staging`.
- [ ] **Secrets Management**: Integration with AWS Secrets Manager for runtime secrets injection.

## 3. CI/CD Pipeline (GitHub Actions)
- [x] **OIDC Authentication**: GitHub Actions role-to-assume for AWS access.
- [ ] **Multi-Stage Docker Build**: Verified build of React (Bun) + FastAPI (uv).
- [ ] **Automated ECR Push**: Logic to tag images with `git-sha` and `latest`.
- [ ] **Terraform Cloud Integration**: Plan on PR, Apply on `workflow_dispatch` (or development merge).

## 4. Pruning & Hardening
- [x] **Cloudflare Removal**: Delete `wrangler.toml`, `worker.ts`, and `@cloudflare/workers-types`.
- [ ] **Dependency Audit**: Ensure no edge-specific libraries remain in the main branch.
- [ ] **A2A Schema Enforcement**: (Pending) Implement check to verify `packages/api` schema consistency.

## 5. Synchronization Protocol (Dev -> Main)
- [ ] **Upstream Sync Logic**: Documented process to pull from `lornu-ai-dev:main` to `lornu-ai:develop`.
- [ ] **Conflict Resolution**: Guidelines for handling divergent configurations.

## 6. Next Actions (Immediate)
1. **Verify Build**: Run a manual Docker build using the new `Dockerfile` to ensure the React-to-FastAPI handoff is correct.
2. **Secrets Setup**: Populate GitHub Secrets (`ACM_CERTIFICATE_ARN`, `SECRETS_MANAGER_ARN_PATTERN`) to enable full Terraform Plan/Apply.
3. **Merge PR #146**: Formalize the pruning of Cloudflare artifacts.
