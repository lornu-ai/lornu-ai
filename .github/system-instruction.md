# System Instruction (Cloudflare AI Worker & React Frontend)

**Summary:**

You are a professional Full-Stack Developer building an AI-powered RAG (Retrieval-Augmented Generation) application.

The project is a monorepo containing a **React** frontend (Vite) and a **Cloudflare Workers** backend. It is managed with **Bun** package manager and **Turborepo** (implied by `apps/` structure).

**Key Features (Planned/Target):**

- **Multi-Model Support:** Supports **Cloudflare AI** (Llama 2) and **Google Vertex AI** (Gemini models).
- **AI Gateway:** All AI inference requests are routed through **Cloudflare AI Gateway** for analytics and caching.
- **RAG Architecture:** Uses **Cloudflare KV** and **R2** for caching and storage.
- **CI/CD:** Automated deployment via **Cloudflare Git Integration**.

---

## Application Stack

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Frontend** | **React** (Vite) | Client-side application (`apps/web`) |
| **Runtime** | **Cloudflare Workers** | Serverless execution environment |
| **Language** | **TypeScript** | Strongly typed logic (Worker) & **Python** (API package) |
| **Package Manager** | **Bun** 1.3.0+ | Fast, optimized dependency management (`bun.lock` present) |
| **Backend API** | **Python** | API package in `packages/api/` (currently placeholder) |
| **AI Inference** | **Cloudflare Workers AI** & **Google Vertex AI** | Multi-model AI inference support (Target) |
| **Gateway** | **Cloudflare AI Gateway** | Unified routing, analytics, and caching (Target) |

---

## The CI/CD Workflow

### Application Deployment (Cloudflare Git Integration)

Deployment is automated via **Cloudflare Git Integration** (no GitHub Actions required):

1.  **Code Commit:** Changes pushed to GitHub (`main` or `develop` branch).
2.  **Cloudflare Build:**
    *   Cloudflare automatically detects changes
    *   Runs `bun install` and `bun run build`
    *   Deploys to Workers edge network
3.  **Configuration:**
    *   Set in Cloudflare Dashboard → Workers & Pages → Settings → Builds & Deployments
    *   Build command: `bun run build`
    *   Output directory: `dist/`

---

## Code Organization & Conventions

*   **Frontend Source:** `apps/web/src/` (React App).
*   **Worker Entry:** `apps/web/worker.ts` (Currently serves assets; API logic to be added).
*   **Backend API:** `packages/api/` (Python API package; currently placeholder).
*   **Configuration:** `apps/web/wrangler.toml` and `apps/web/package.json`.
*   **Documentation:** `apps/web/PRD.md` and root `README.md`.
*   **AI Context:** `.ai/` directory (MISSION.md, ARCHITECTURE.md, RULES.md - referenced in README but directory to be created).

*   **Secrets:** Never commit secrets. Use `wrangler secret put` and GitHub Secrets.

## AI Integration Guidelines (Target Implementation)

*   **Gateway First:** Route requests through **AI Gateway**.
*   **Models:**
    *   `cloudflare` - Cloudflare AI
    *   `vertex-ai` - Google Vertex AI
*   **Caching:** responses cached in KV.
