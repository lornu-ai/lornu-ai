import os
import logging
import uvicorn
from packages.api.src.main import app

def main():
    logger = logging.getLogger("uvicorn")

    # Parse PORT from environment with robust error handling
    try:
        port = int(os.getenv("PORT", "8080"))
    except ValueError:
        port = 8080
        logger.warning("Invalid PORT environment variable, defaulting to 8080")

    # Reload logic (optional, string import required for reload)
    reload_enabled = os.getenv("RELOAD_ENABLED", "false").lower() == "true"

    logger.info(f"Starting server on port {port} (reload={reload_enabled})")

    if reload_enabled:
         # Use string import for reload functionality
         uvicorn.run("packages.api.src.main:app", host="0.0.0.0", port=port, reload=True)
    else:
         uvicorn.run(app, host="0.0.0.0", port=port)

if __name__ == "__main__":
    main()
