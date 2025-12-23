import logging
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

class MediaAgent:
    def __init__(self):
        self.enabled = False
        try:
            import rembg
            from PIL import Image
            self.rembg = rembg
            self.Image = Image
            self.enabled = True
        except ImportError as e:
            logger.warning(f"rembg or PIL not available. Background removal disabled. Error: {e}")

    def remove_background(self, input_path: Path, output_path: Path) -> Optional[Path]:
        """
        Removes background from an image using rembg (u2net).

        Args:
            input_path: Path to the input image
            output_path: Path where the processed image should be saved

        Returns:
            Path to the output file if successful, None otherwise.
        """
        if not self.enabled:
            raise ImportError("rembg is not installed or failed to load")

        try:
            if not input_path.exists():
                raise FileNotFoundError(f"Input file not found: {input_path}")

            logger.info(f"Removing background from: {input_path}")

            # Load image using PIL
            inp = self.Image.open(input_path)

            # Process with rembg
            output = self.rembg.remove(inp)

            # Save output
            output.save(output_path)

            logger.info(f"Background removed: {output_path}")
            return output_path

        except Exception as e:
            logger.error(f"Background removal failed: {e}")
            raise
