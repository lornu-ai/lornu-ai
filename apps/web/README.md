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

- Node.js 20+
- npm or bun
- Wrangler CLI (installed as dev dependency)
- [Pre-commit](https://pre-commit.com/) (recommended for code quality & security)


### Development Tools (Pre-commit)

This project uses pre-commit hooks to enforce code quality and security standards (blocking secrets, checking syntax).

1. **Install pre-commit:**
   ```bash
   brew install pre-commit  # macOS
   pip install pre-commit   # Universal
   ```

2. **Install hooks in the repo:**
   ```bash
   pre-commit install
   ```

3. **Run checks manually:**
   ```bash
   pre-commit run --all-files
   ```

### Local Development

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Run development server with Vite:**
   ```bash
   npm run dev
   ```
   This starts the Vite dev server at `http://localhost:5173`

3. **Test with Wrangler (production-like environment):**
   ```bash
   npm run build
   npx wrangler dev
   ```
   This runs the actual worker locally with the built assets

### Build

Build the production bundle:
```bash
npm run build
```

The output is generated in the `dist/` directory.

## Deployment

### Cloudflare Git Integration (Recommended)

This project uses **Cloudflare's Git integration** for automatic deployments:

1. Pushing to `main` branch triggers automatic deployment to production
2. Pushing to `develop` branch triggers deployment to staging (if configured)
3. No GitHub Actions required - Cloudflare handles the build and deployment

**Setup:**
- Configure in Cloudflare Dashboard → Workers & Pages → Your Project → Settings → Builds & Deployments
- Cloudflare automatically detects the `wrangler.toml` configuration

### Manual Deployment

Deploy manually using Wrangler:
```bash
npm run build
npx wrangler deploy
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
npx wrangler secret put SECRET_NAME
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

- Use `npx wrangler dev` instead of `npm run dev` to test the production-like environment
- The worker serves assets from the `dist/` directory after build
- Deploy is automatic via Cloudflare Git integration

## Troubleshooting

### MIME Type Issues

If assets aren't loading correctly, check:
1. File extensions are recognized in `worker.ts` MIME_TYPES map
2. The worker is properly serving from the ASSETS binding
3. Content-Type headers in browser DevTools Network tab

### Local Development Issues

If `wrangler dev` fails:
```bash
# Ensure you have the latest wrangler
npm install wrangler@latest --save-dev

# Clear wrangler cache
rm -rf ~/.wrangler

# Rebuild the app
npm run build
npx wrangler dev
```

### Deployment Issues

If deployment fails:
```bash
# Check wrangler authentication
npx wrangler whoami

# Re-authenticate if needed
npx wrangler login
```

## License

The Spark Template files and resources from GitHub are licensed under the terms of the MIT license, Copyright GitHub, Inc.
