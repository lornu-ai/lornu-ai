import os
import logging
import uvicorn
from .src.main import app

def main():
    logger = logging.getLogger("uvicorn")
    
    # Parse PORT from environment with robust error handling
    try:
        port = int(os.getenv("PORT", "8000"))
    except ValueError:
        port = 8000
        logger.warning(f"Invalid PORT environment variable, defaulting to 8000")
    
    # Make reload configurable (development-only feature)
    reload_enabled = os.getenv("RELOAD_ENABLED", "false").lower() == "true"
    
    uvicorn.run("src.main:app", host="0.0.0.0", port=port, reload=reload_enabled)

if __name__ == "__main__":
    main()
