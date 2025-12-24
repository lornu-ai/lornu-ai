from fastapi import FastAPI
from .router.message_router import router as api_router

app = FastAPI(title="Lornu API", description="Backend API for Lornu Agents")

app.include_router(api_router, prefix="/api/v1")

@app.get("/")
def health_check():
    return {"status": "ok", "service": "api"}
