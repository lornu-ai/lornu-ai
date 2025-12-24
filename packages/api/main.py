"""
Lornu AI FastAPI Backend
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os
from pathlib import Path

app = FastAPI(title="Lornu AI", version="0.1.0")

# CORS configuration
# TODO: Restrict CORS origins in production to specific domains
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for staging; restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/health")
async def health():
    """Health check endpoint"""
    return {"status": "ok"}

@app.get("/health")
async def health_root():
    """Health check endpoint (for ALB)"""
    return {"status": "ok"}

# Mount static files for frontend (if dist exists)
dist_path = Path(__file__).parent.parent.parent / "apps" / "web" / "dist"
if dist_path.exists():
    app.mount("/", StaticFiles(directory=str(dist_path), html=True), name="static")


def main():
    import uvicorn
    port = int(os.environ.get("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)


if __name__ == "__main__":
    main()

