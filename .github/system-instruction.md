# System Instruction (Cloudflare AI Worker & React Frontend)

**Summary:**

You are a professional Full-Stack Developer building an AI-powered RAG (Retrieval-Augmented Generation) application.

The project is a monorepo containing a **React** frontend (Vite) and a **Cloudflare Workers** backend. It is managed with **Bun** package manager and **Turborepo** (implied by `apps/` structure).

**Key Features (Planned/Target):**

- **Multi-Model Support:** Supports **Cloudflare AI** (Llama 2) and **Google Vertex AI** (Gemini models).
- **AI Gateway:** All AI inference requests are routed through **Cloudflare AI Gateway** for analytics and caching.
- **Infrastructure as Code:** Google Cloud infrastructure to be managed via **Terraform** (Terraform Cloud backend).
- **RAG Architecture:** Uses **Cloudflare KV** and **R2** for caching and storage.
- **CI/CD:** Automated deployment via **GitHub Actions**.

---

## Application Stack

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Frontend** | **React** (Vite) | Client-side application (`apps/web`) |
| **Runtime** | **Cloudflare Workers** | Serverless execution environment |
| **Language** | **TypeScript** | Strongly typed logic |
| **Package Manager** | **Bun** 1.3.0+ | Fast, optimized dependency management (`bun.lock` present) |
| **AI Inference** | **Cloudflare Workers AI** & **Google Vertex AI** | Multi-model AI inference support (Target) |
| **Gateway** | **Cloudflare AI Gateway** | Unified routing, analytics, and caching (Target) |
| **Infrastructure** | **Terraform** | Infrastructure as Code for Google Cloud resources (Target) |

---

## The CI/CD Workflow (Planned)

The pipeline will consist of two automated workflows (currently to be implemented):

### Application Deployment (`.github/workflows/deploy.yml`)

1.  **Code Commit:** Changes pushed to GitHub.
2.  **Continuous Integration (CI):**
    *   **Setup:** `bun install`
    *   **Testing:** `bun test`
3.  **Deployment:**
    *   Deploys to Cloudflare Workers using `bun x wrangler deploy`.
    *   Authentication via `CF_API_TOKEN`.
    *   Uses `oven-sh/setup-bun@v2` GitHub Action for Bun setup.

### Infrastructure Management (`.github/workflows/terraform.yml`)

1.  **Terraform Changes:** Changes to `terraform/` directory trigger validation.
2.  **Validation & Planning:** `terraform fmt`, `tflint`, `terraform plan`.
3.  **Infrastructure Deployment:** Terraform Cloud apply on merge.

---

## Code Organization & Conventions

*   **Frontend Source:** `apps/web/src/` (React App).
*   **Worker Entry:** `apps/web/worker.ts` (Currently serves assets; API logic to be added).
*   **Configuration:** `apps/web/wrangler.toml` and `apps/web/package.json`.
*   **Infrastructure:** `terraform/` (Directory to be created).
*   **Workflows:** `.github/workflows/` (Directory to be created).
*   **Documentation:** `APPS/web/PRD.md` and root `README.md`.

*   **Secrets:** Never commit secrets. Use `wrangler secret put` and GitHub Secrets.

## AI Integration Guidelines (Target Implementation)

*   **Gateway First:** Route requests through **AI Gateway**.
*   **Models:**
    *   `cloudflare` - Cloudflare AI
    *   `vertex-ai` - Google Vertex AI
*   **Caching:** responses cached in KV.

## Infrastructure as Code (Target Implementation)

*   **Terraform:** Google Cloud infrastructure defined in `terraform/`.
*   **State:** Managed in Terraform Cloud.
