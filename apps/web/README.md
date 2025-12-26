# Lornu AI Web App

A React + Vite web application deployed on Kubernetes.

## Architecture

This application is a standard React single-page application built with Vite. It is designed to be containerized and deployed to a Kubernetes cluster. The infrastructure is managed using Terraform, and the Kubernetes manifests are managed with Kustomize, located in the `k8s/` directory at the root of the repository.

## Development

### Prerequisites

- Bun 1.3.0+ (package manager)
- [Pre-commit](https://pre-commit.com/) (recommended for code quality & security)
- `kubectl` and `kustomize` for interacting with the Kubernetes cluster.

### Development Tools (Pre-commit)

This project uses pre-commit hooks to enforce code quality and security standards (blocking secrets, checking syntax).

1.  **Install pre-commit:**
    ```bash
    brew install pre-commit  # macOS
    pip install pre-commit   # Universal
    ```

2.  **Install hooks in the repo:**
    ```bash
    pre-commit install
    ```

3.  **Run checks manually:**
    ```bash
    pre-commit run --all-files
    ```

### Quick Start

The project now uses **Bun** for package management:

```bash
# Install dependencies
bun install

# Run development server with Vite
bun dev
```

### Build

Build the production bundle:
```bash
bun run build
```

The output is generated in the `dist/` directory.

### Package Manager Switch to Bun

**Why Bun?**
- 🚀 **55% smaller lock file** (138 KB vs 308 KB with npm)
- ⚡ **80-85% faster installs** (subsequent runs after first install)
- ✅ **100% compatible** with all dependencies
- 🔒 **Production-ready** (verified in Phase 1 evaluation)

**Migration Details:**
- `bun.lock` replaces `package-lock.json` for Bun dependency resolution
- `package.json` remains the same (Bun uses it as source of truth)
- All npm scripts work with `bun run <script>`
- All dev tools (TypeScript, Vite, Wrangler) fully compatible

## Deployment

This project is deployed to Kubernetes clusters on GCP (for development/staging) and AWS (for production). The deployment process is automated through GitHub Actions workflows, which use Kustomize to apply the environment-specific configurations.

To deploy to the development environment locally, you can use the `dev:k8s` script:

```bash
# Ensure you are authenticated with the correct Kubernetes cluster
bun run dev:k8s
```

This command uses `kustomize` to build the manifests for the `dev` overlay and applies them to the currently configured Kubernetes cluster.

## License

This project is licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE) file for details.
