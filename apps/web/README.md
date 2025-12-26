# Lornu AI Web App

A React + Vite web application served by a Python FastAPI backend.

## Architecture

This project consists of a React single-page application (SPA) and a Python FastAPI backend. The backend is responsible for serving the static files of the React application and providing an API. The entire application is designed to be containerized with Docker and deployed to a Kubernetes cluster.

### Key Components

- **`apps/web/src/`**: The React application source code, built with Vite.
- **`packages/api/src/main.py`**: The FastAPI application that serves the frontend and provides the API.
- **`Dockerfile`**: Defines the container image for the application.
- **`k8s/`**: Contains the Kubernetes manifests for deploying the application.

## Development

### Prerequisites

- Bun 1.3.0+ (for the frontend)
- Python 3.11+ and `uv` (for the backend)
- [Pre-commit](https://pre-commit.com/) (recommended for code quality & security)


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

To get the application running locally, you'll need to start both the frontend and backend services.

#### Frontend (Vite Dev Server)

In the `apps/web` directory:
```bash
# Install dependencies
bun install

# Run development server
bun dev
```

#### Backend (FastAPI Server)

In the `packages/api` directory:
```bash
# Install dependencies
uv sync

# Run development server
uv run python main.py
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
- All dev tools (TypeScript, Vite) fully compatible

## Deployment

The application is deployed to a Kubernetes cluster. The deployment process is defined by the Kubernetes manifests in the `k8s/` directory and is automated via GitHub Actions workflows.

## Configuration

### Environment Variables

Configuration for the application is managed through Kubernetes ConfigMaps and Secrets. These are applied to the environment at runtime.

### Secrets

Secrets, such as API keys, are managed using Kubernetes Secrets. For local development, you can use a `.env` file in the `packages/api` directory.

See [`CONTACT_FORM_SETUP.md`](./CONTACT_FORM_SETUP.md) for detailed contact form configuration.

## Troubleshooting

### Local Development Issues

If `bun dev` fails:
```bash
# Ensure dependencies are installed
bun install

# Clear Bun cache if needed
rm -rf ~/.bun
```

If the backend fails to start:
```bash
# Ensure dependencies are installed
uv sync
```

### Contact Form / Email Issues

If the contact form isn't sending emails:
1. Verify the `RESEND_API_KEY` is set in your environment or Kubernetes Secret.
2. Check the domain is verified in the Resend dashboard.
3. Review the logs from the backend pod for any errors.
4. See [`CONTACT_FORM_SETUP.md`](./CONTACT_FORM_SETUP.md) for detailed troubleshooting.

## License

The Spark Template files and resources from GitHub are licensed under the terms of the MIT license, Copyright GitHub, Inc.
