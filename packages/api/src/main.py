from pathlib import Path
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from .router.message_router import router as api_router

app = FastAPI(title="Lornu API", description="Backend API for Lornu Agents")

# API routes
app.include_router(api_router, prefix="/api")

# Serve frontend static files
FRONTEND_DIR = Path("/app/apps/web/dist")

if FRONTEND_DIR.exists():
    # Serve static assets (js, css, images, etc.)
    app.mount("/assets", StaticFiles(directory=FRONTEND_DIR / "assets"), name="assets")

    # Serve index.html for all other routes (SPA fallback)
    @app.get("/{full_path:path}")
    async def serve_spa(full_path: str):
        # Try to serve the exact file first
        file_path = FRONTEND_DIR / full_path
        if file_path.is_file():
            return FileResponse(file_path)
        # Fall back to index.html for SPA routing
        return FileResponse(FRONTEND_DIR / "index.html")
else:
    # Fallback health check at root when no frontend
    @app.get("/")
    def root():
        return {"status": "ok", "service": "api", "frontend": "not_available"}
