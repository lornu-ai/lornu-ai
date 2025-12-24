import os
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional
import time

app = FastAPI(title="Lornu AI API")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Rate limiting storage (in-memory for now)
rate_limit_store: dict[str, list[float]] = {}
RATE_LIMIT_WINDOW = 3600  # 1 hour in seconds
RATE_LIMIT_MAX = 5  # 5 requests per hour


class ContactRequest(BaseModel):
    name: str
    email: EmailStr
    message: str

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        if not v or len(v.strip()) == 0:
            raise ValueError("Name is required")
        if len(v) > 100:
            raise ValueError("Name must be less than 100 characters")
        return v.strip()

    @field_validator("message")
    @classmethod
    def validate_message(cls, v: str) -> str:
        if not v or len(v.strip()) == 0:
            raise ValueError("Message is required")
        if len(v) > 1000:
            raise ValueError("Message must be less than 1000 characters")
        return v.strip()


def check_rate_limit(ip: str) -> bool:
    """Check if IP has exceeded rate limit."""
    current_time = time.time()
    if ip not in rate_limit_store:
        rate_limit_store[ip] = []
    
    # Clean old entries
    rate_limit_store[ip] = [
        t for t in rate_limit_store[ip] 
        if current_time - t < RATE_LIMIT_WINDOW
    ]
    
    # Check limit
    if len(rate_limit_store[ip]) >= RATE_LIMIT_MAX:
        return False
    
    rate_limit_store[ip].append(current_time)
    return True


@app.get("/api/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "ok"}


@app.post("/api/contact")
async def contact_form(contact: ContactRequest, request: Request):
    """
    Handle contact form submissions.
    
    Note: Email sending requires RESEND_API_KEY environment variable.
    For now, this logs the contact request.
    """
    # Get client IP
    client_ip = request.client.host if request.client else "unknown"
    
    # Check rate limit
    bypass_secret = os.getenv("RATE_LIMIT_BYPASS_SECRET")
    bypass_header = request.headers.get("X-Bypass-Rate-Limit")
    
    if not (bypass_secret and bypass_header == bypass_secret):
        if not check_rate_limit(client_ip):
            raise HTTPException(
                status_code=429,
                detail="Too many requests. Please try again later."
            )
    
    # TODO: Implement actual email sending with Resend
    # For now, log the request
    print(f"Contact form submission from {contact.email}:")
    print(f"  Name: {contact.name}")
    print(f"  Email: {contact.email}")
    print(f"  Message: {contact.message}")
    
    resend_api_key = os.getenv("RESEND_API_KEY")
    if resend_api_key:
        # TODO: Send email using Resend API
        pass
    
    return {
        "success": True,
        "message": "Thank you for contacting us. We'll get back to you soon!"
    }


# Mount static files for frontend (if built)
static_dir = os.path.join(os.path.dirname(__file__), "../../apps/web/dist")
if os.path.exists(static_dir):
    app.mount("/", StaticFiles(directory=static_dir, html=True), name="static")


def main():
    """Run the application with uvicorn."""
    import uvicorn
    port = int(os.getenv("PORT", "8080"))
    uvicorn.run(app, host="0.0.0.0", port=port)


if __name__ == "__main__":
    main()
