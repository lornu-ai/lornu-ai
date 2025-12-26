import shutil
import tempfile
import logging
from pathlib import Path
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import FileResponse
from starlette.background import BackgroundTask

from ..agents.image_agent import ImageAgent
from ..agents.media_agent import MediaAgent
from ..agents.email_agent import EmailAgent
from pydantic import BaseModel, EmailStr

logger = logging.getLogger(__name__)

router = APIRouter()

@router.get("/health", include_in_schema=False)
@router.head("/health", include_in_schema=False)
def health_check():
    return {"status": "ok", "service": "api"}

image_agent = ImageAgent()
media_agent = MediaAgent()
email_agent = EmailAgent()

class ContactRequest(BaseModel):
    name: str
    email: EmailStr
    message: str

def cleanup_temp_dir(path: str):
    """Deletes the temporary directory and its contents."""
    try:
        shutil.rmtree(path, ignore_errors=True)
        logger.debug(f"Cleaned up temp dir: {path}")
    except Exception as e:
        logger.warning(f"Failed to cleanup temp dir {path}: {e}")

@router.post("/vectorize")
async def vectorize_image(file: UploadFile = File(...)):
    """
    Endpoint to convert a raster image to SVG.
    """
    if not image_agent.enabled:
        raise HTTPException(status_code=501, detail="Vectorization service unavailable (vtracer missing)")

    # Create a temp directory explicitly (not context manager) to persist during streaming
    temp_dir = tempfile.mkdtemp()
    temp_path = Path(temp_dir)

    try:
        input_file = temp_path / file.filename
        # Fix: Ensure clean extension replacement (e.g. .png -> .svg)
        output_file = temp_path / f"{Path(file.filename).stem}.svg"

        # Save upload to temp
        with open(input_file, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Process
        result = image_agent.process_vectorization(input_file, output_file)

        if result and result.exists():
            # Return the file with a background task to clean up the temp dir
            return FileResponse(
                result,
                media_type="image/svg+xml",
                filename=result.name,
                background=BackgroundTask(cleanup_temp_dir, temp_dir)
            )
        else:
            cleanup_temp_dir(temp_dir)
            raise HTTPException(status_code=500, detail="Vectorization failed")

    except Exception as e:
        cleanup_temp_dir(temp_dir)
        logger.error(f"Error in vectorize_image: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/remove-bg")
async def remove_background(file: UploadFile = File(...)):
    """
    Endpoint to remove background from an image.
    """
    if not media_agent.enabled:
        raise HTTPException(status_code=501, detail="Background removal service unavailable (rembg missing)")

    temp_dir = tempfile.mkdtemp()
    temp_path = Path(temp_dir)

    try:
        input_file = temp_path / file.filename
        # Output as PNG to preserve transparency
        output_filename = f"{Path(file.filename).stem}_nobg.png"
        output_file = temp_path / output_filename

        with open(input_file, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        result = media_agent.remove_background(input_file, output_file)

        if result and result.exists():
            return FileResponse(
                result,
                media_type="image/png",
                filename=result.name,
                background=BackgroundTask(cleanup_temp_dir, temp_dir)
            )
        else:
            cleanup_temp_dir(temp_dir)
            raise HTTPException(status_code=500, detail="Background removal failed")

    except Exception as e:
        cleanup_temp_dir(temp_dir)
        logger.error(f"Error in remove_background: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/contact")
def contact_form(request: ContactRequest):
    """
    Endpoint for contact form submissions.
    """
    if not email_agent.enabled:
        # Fallback during migration if Resend is not yet configured
        logger.warning(f"Contact form submission received but email is disabled: {request.name} <{request.email}>")
        return {"status": "received", "info": "Email delivery is currently disabled for maintenance."}

    success = email_agent.send_contact_email(
        name=request.name,
        email=request.email,
        message=request.message
    )

    if success:
        return {"status": "success", "message": "Thank you for your message. We will get back to you soon."}
    else:
        raise HTTPException(status_code=500, detail="Failed to send message. Please try again later.")
