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
        # Sanitize filename to prevent path traversal
        safe_filename = Path(file.filename).name
        input_file = temp_path / safe_filename

        # Ensure clean extension replacement (e.g. .png -> .svg)
        # Use .with_suffix() to correctly handle extension replacement
        output_file = input_file.with_suffix(".svg")

        # Handle edge case where input and output filenames are identical
        # (e.g. uploading 'image.svg' to verify/clean it)
        if input_file == output_file:
            output_file = temp_path / f"{input_file.stem}_vectorized.svg"

        # Save upload to temp
        with open(input_file, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Process
        result = image_agent.process_vectorization(input_file, output_file)

        if not (result and result.exists()):
            raise Exception("Vectorization failed")

        return FileResponse(
            result,
            media_type="image/svg+xml",
            filename=result.name,
            background=BackgroundTask(cleanup_temp_dir, temp_dir)
        )
    except Exception as e:
        cleanup_temp_dir(temp_dir)
        logger.error(f"Error during image vectorization: {e}")
        raise HTTPException(status_code=500, detail="Image processing failed.")

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
        # Sanitize filename to prevent path traversal
        safe_filename = Path(file.filename).name
        input_file = temp_path / safe_filename

        # Output as PNG to preserve transparency
        output_filename = f"{Path(safe_filename).stem}_nobg.png"
        output_file = temp_path / output_filename

        with open(input_file, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        result = media_agent.remove_background(input_file, output_file)

        if not (result and result.exists()):
            raise Exception("Background removal failed")

        return FileResponse(
            result,
            media_type="image/png",
            filename=result.name,
            background=BackgroundTask(cleanup_temp_dir, temp_dir)
        )
    except Exception as e:
        cleanup_temp_dir(temp_dir)
        logger.error(f"Error during background removal: {e}")
        raise HTTPException(status_code=500, detail="Image processing failed.")

@router.post("/contact")
def contact_form(request: ContactRequest):
    """
    Endpoint for contact form submissions.
    """
    if not email_agent.enabled:
        # Fallback during migration if Resend is not yet configured
        logger.warning(f"Contact form submission received but email is disabled: {request.name} <{request.email}>")
        return {"status": "success", "message": "Email delivery is currently disabled for maintenance, but we have received your message."}

    success = email_agent.send_contact_email(
        name=request.name,
        email=request.email,
        message=request.message
    )

    if success:
        return {"status": "success", "message": "Thank you for your message. We will get back to you soon."}
    else:
        raise HTTPException(status_code=500, detail="Failed to send message. Please try again later.")
