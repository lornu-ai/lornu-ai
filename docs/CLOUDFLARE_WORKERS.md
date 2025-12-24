# Cloudflare Workers Development

**Note**: As of Issue #140, Cloudflare Workers code has been removed from the main `lornu-ai` repository to keep it AWS/GCP native.

## For Cloudflare Workers Development

If you need to work with Cloudflare Workers, please use the **`lornu-ai-dev`** fork:

- **Repository**: [lornu-ai/lornu-ai-dev](https://github.com/lornu-ai/lornu-ai-dev) (if exists)
- **Purpose**: Rapid prototyping and development environment
- **Infrastructure**: Cloudflare Workers (Edge)
- **Artifacts**: `wrangler.toml`, Worker scripts

## Main Repository Focus

This repository (`lornu-ai`) focuses on:

- **Enterprise Staging/Production**
- **Infrastructure**: AWS EKS / GCP GKE via Terraform
- **CI/CD**: GitHub Actions → AWS ECR → EKS
- **Artifacts**: Docker images, Kubernetes manifests

## Architecture

See `docs/EPIC_ARCH_SPLIT.md` for the full architecture split strategy.

## Migration

The following files were removed in compliance with Issue #140:

- `apps/web/worker.ts` - Cloudflare Worker implementation
- `wrangler.toml` - Cloudflare configuration
- Related test files

These files are now maintained in the `lornu-ai-dev` fork for Cloudflare-specific development.
