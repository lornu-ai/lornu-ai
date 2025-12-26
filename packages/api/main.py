import os
import uvicorn
from .src.main import app

def main():
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("src.main:app", host="0.0.0.0", port=port, reload=True)

if __name__ == "__main__":
    main()
