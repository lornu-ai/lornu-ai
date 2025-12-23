import shutil
import tempfile
from pathlib import Path
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import FileResponse

from ..agents.image_agent import ImageAgent
from ..agents.media_agent import MediaAgent

router = APIRouter()
image_agent = ImageAgent()
media_agent = MediaAgent()

@router.post("/vectorize")
async def vectorize_image(file: UploadFile = File(...)):
    """
    Endpoint to convert a raster image to SVG.
    """
    # Create a temp directory for processing
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        input_file = temp_path / file.filename
        output_file = temp_path / f"{file.filename}.svg"

        # Save upload to temp
        with open(input_file, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Process
        result = image_agent.process_vectorization(input_file, output_file)

        if result and result.exists():
            # Return the file
            # Note: In a real async worker pattern (A2A), we might upload this to GCS
            # and return a URL, but for now we stream the file back.
            return FileResponse(result, media_type="image/svg+xml", filename=result.name)
        else:
            raise HTTPException(status_code=500, detail="Vectorization failed")

@router.post("/remove-bg")
async def remove_background(file: UploadFile = File(...)):
    """
    Endpoint to remove background from an image.
    """
    if not media_agent.enabled:
        raise HTTPException(status_code=501, detail="Background removal service unavailable (rembg missing)")

    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        input_file = temp_path / file.filename
        # Output as PNG to preserve transparency
        output_filename = f"{Path(file.filename).stem}_nobg.png"
        output_file = temp_path / output_filename

        with open(input_file, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        result = media_agent.remove_background(input_file, output_file)

        if result and result.exists():
            return FileResponse(result, media_type="image/png", filename=result.name)
        else:
            raise HTTPException(status_code=500, detail="Background removal failed")
