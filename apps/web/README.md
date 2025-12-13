# Lornu AI Web App

A React + Vite web application deployed on Cloudflare Workers with custom asset serving.

## Architecture

This application uses **Cloudflare Workers** (not Cloudflare Pages) to serve static assets with custom request handling. The architecture provides:

- **Custom MIME type handling**: Ensures all static assets are served with correct Content-Type headers
- **Cloudflare Workers Runtime**: Leverages edge computing for fast, global content delivery
- **Asset binding**: The built React app is served through the ASSETS binding in the worker

### Key Components

- **`worker.ts`**: Cloudflare Worker that intercepts requests and ensures proper Content-Type headers
- **`wrangler.toml`**: Worker configuration including asset directory and domain routing
- **`src/`**: React application source code built with Vite

## Development

### Prerequisites

- Bun 1.3.0+ (package manager)
- Wrangler CLI (installed as dev dependency)

### Quick Start

The project now uses **Bun** for package management (Phase 2 migration):

```bash
# Install dependencies
bun install

# Run development server with Vite
bun dev

# Run in production-like environment with Wrangler
bun run build
bun x wrangler dev
```

### Local Development Workflow

#### Option 1: Vite Dev Server (Fastest Development)

1. **Install dependencies:**
   ```bash
   bun install
   ```

2. **Run development server:**
   ```bash
   bun dev
   ```
   This starts the Vite dev server at `http://localhost:5173` with hot module replacement.

#### Option 2: Wrangler Dev (Production-Like Environment)

For testing the actual Cloudflare Workers configuration:

1. **Build the app:**
   ```bash
   bun run build
   ```

2. **Run worker locally:**
   ```bash
   bun x wrangler dev
   ```
   This runs the actual worker locally with the built assets at `http://localhost:8787`

3. **Combined script:**
   ```bash
   bun run dev:worker
   ```
   Runs build and wrangler dev together for full testing

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

### Cloudflare Git Integration (Recommended)

This project uses **Cloudflare's Git integration** for automatic deployments:

1. Pushing to `main` branch triggers automatic deployment to production
2. Pushing to `develop` branch triggers deployment to staging (if configured)
3. Cloudflare handles the build and deployment automatically

**Setup:**
- Configure in Cloudflare Dashboard → Workers & Pages → Your Project → Settings → Builds & Deployments
- Cloudflare automatically detects the `wrangler.toml` configuration
- Ensure Cloudflare build settings use Bun (v1.3.0+) in Builds & Deployments settings

### Manual Deployment

Deploy manually using Wrangler:
```bash
bun run build
bun x wrangler deploy
```

**Note:** Requires Cloudflare API token configured:
```bash
wrangler login
```

## Configuration

### Environment Variables

Currently no environment variables required. Add them in `wrangler.toml` if needed:

```toml
[vars]
API_URL = "https://api.example.com"
```

For secrets:
```bash
bun x wrangler secret put SECRET_NAME
```

### Domain Configuration

Production domains are configured in `wrangler.toml`:
- `lornu.ai`
- `www.lornu.ai`

**Important:** Custom domains must be added in Cloudflare Dashboard first before the routes will work.

## Migration from Cloudflare Pages

This project was migrated from Cloudflare Pages to Cloudflare Workers to gain:

1. **Better control**: Custom request/response handling in the worker
2. **MIME type fixes**: Resolved issues with Content-Type headers for static assets
3. **Flexibility**: Can add API routes, authentication, or other logic in the worker

### What Changed:

- ❌ Removed: `.github/workflows/deploy.yml` (GitHub Actions workflow)
- ✅ Added: `worker.ts` (Cloudflare Worker for asset serving)
- ✅ Modified: `wrangler.toml` (from Pages config to Workers config)
- ✅ Added: Wrangler and Workers types to dependencies

### For Developers:

- Use `bun x wrangler dev` instead of `bun dev` to test the production-like environment
- The worker serves assets from the `dist/` directory after build
- Deploy is automatic via Cloudflare Git integration

## Troubleshooting

### MIME Type Issues

If assets aren't loading correctly, check:
1. File extensions are recognized in `worker.ts` MIME_TYPES map
2. The worker is properly serving from the ASSETS binding
3. Content-Type headers in browser DevTools Network tab

### Local Development Issues

If `bun dev` or `wrangler dev` fails:
```bash
# Ensure dependencies are installed
bun install

# Clear Bun cache if needed
rm -rf ~/.bun

# Ensure wrangler is up to date
bun add -D wrangler@latest

# Rebuild the app
bun run build
bun x wrangler dev
```

### Deployment Issues

If deployment fails:
```bash
# Check wrangler authentication
bun x wrangler whoami

# Re-authenticate if needed
bun x wrangler login

# Verify Bun can execute wrangler
bun x wrangler --version
```

## License

The Spark Template files and resources from GitHub are licensed under the terms of the MIT license, Copyright GitHub, Inc.
