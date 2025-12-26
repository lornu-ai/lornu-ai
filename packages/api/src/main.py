from fastapi import FastAPI
from fastapi.responses import JSONResponse
from .router.message_router import router as api_router

app = FastAPI(title="Lornu API", description="Backend API for Lornu Agents")

app.include_router(api_router, prefix="/api/v1")

@app.get("/")
def health_check():
    return {"status": "ok", "service": "api"}

@app.post("/_spark/loaded")
def spark_loaded():
    """
    Endpoint to handle Spark library lifecycle notification.
    Spark signals when the library is ready via this POST endpoint.
    """
    return JSONResponse(status_code=200, content={"status": "loaded"})
