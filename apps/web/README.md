# Lornu AI Web App

A React + Vite web application built with Bun and deployed via Plan A (Kubernetes).

## Architecture

This application is built as a Static Site that is served by the Backend API (`packages/api`).

- **Frontend**: React + Vite (TS), managed by **Bun**.
- **Serving**: The Python FastAPI backend serves the built assets from `dist/` and provides SPA fallback routing.
- **Deployment**: Deployed as a Docker container to GKE (GCP) or EKS (AWS) namespaces (`lornu-dev`, `lornu-staging`, `lornu-prod`).

## Development

### Prerequisites

- [Bun](https://bun.sh/) 1.3.0+ (package manager)
- [Pre-commit](https://pre-commit.com/) (required for code quality & security)

### Quick Start

```bash
# Install dependencies
bun install

# Run development server with Vite
bun dev

# Run tests
bun run test
```

### Local Development Workflow

1.  **Vite Dev Server**: Starts the HMR server at `http://localhost:5173`.
2.  **K8s Dev**: Build and apply manifests to the local/dev cluster:
    ```bash
    bun run dev:k8s
    ```

### Build

Build the production bundle:
```bash
bun run build
```

The output is generated in the `dist/` directory, which is then picked up by the Docker build process.

## Configuration

### Environment Variables

Frontend configuration is managed via Vite environment variables (`.env`).
Backend configuration (including the contact form email) is managed via Kubernetes ConfigMaps and Secrets.

## Deployment

Deployment is managed by GitHub Actions based on the Plan A model:
- Pushing to `gcp-develop` triggers deployment to the `lornu-dev` namespace on GKE.

---
*Note: Legacy references to Cloudflare Workers are deprecated. This project uses a unified containerized deployment.*
