# Lornu AI Web App

A React + Vite frontend deployed as a container in Kubernetes (see `kubernetes/`).

## Architecture

- **Frontend**: React + Vite app built into static assets.
- **API**: Requests to `/api/*` are handled by the backend service (`packages/api`) behind the same ingress.
- **Runtime**: Served via the Kubernetes ingress in the target environment.

## Development

### Prerequisites

- Bun 1.3.0+ (package manager)
- Pre-commit (optional)

### Quick Start

```bash
# Install dependencies
bun install

# Run development server with Vite
bun dev
```

### Build

```bash
bun run build
```

The output is generated in the `dist/` directory.

## Deployment

This repo deploys via Kubernetes manifests under `kubernetes/` (Kustomize overlays per environment). Build and publish the web image as part of the standard container pipeline, then apply the relevant overlay.

See `kubernetes/README.md` and `kubernetes/K8S_GUIDE.md` for deployment details.

## Contact Form

The contact form posts to `/api/contact`, which is expected to be served by the backend in the Kubernetes deployment. Configuration for email delivery is documented in `apps/web/CONTACT_FORM_SETUP.md`.
