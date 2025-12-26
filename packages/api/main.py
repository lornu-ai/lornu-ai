import os
import logging
import uvicorn
from packages.api.src.main import app

def main():
    port = int(os.getenv("PORT", 8080))
    logger = logging.getLogger("uvicorn")
    logger.info(f"Starting server on port {port}")
    uvicorn.run(app, host="0.0.0.0", port=port)

if __name__ == "__main__":
    main()
