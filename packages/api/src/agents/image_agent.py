import logging
from pathlib import Path
from typing import Optional
import vtracer

logger = logging.getLogger(__name__)

class ImageAgent:
    def process_vectorization(self, input_path: Path, output_path: Path, colormode: str = "color") -> Optional[Path]:
        """
        Converts a raster image to SVG using vtracer (VisionCortex).

        Args:
            input_path: Path to the input image (PNG/JPG)
            output_path: Path where the output SVG should be saved
            colormode: 'color' or 'binary'

        Returns:
            Path to the output file if successful, None otherwise.
        """
        try:
            if not input_path.exists():
                raise FileNotFoundError(f"Input file not found: {input_path}")

            logger.info(f"Vectorizing image: {input_path} (mode={colormode})")

            # vtracer conversion
            # Using defaults for other parameters generally works well for logos
            vtracer.convert_image_to_svg_py(
                str(input_path),
                str(output_path),
                colormode=colormode,
                hierarchical="stacked", # Better for logos/graphics
                mode="spline",          # Spline or polygon
                filter_speckle=4,
                color_precision=6,
                layer_difference=16,
                corner_threshold=60,
                length_threshold=10,
                max_iterations=10,
                splice_threshold=45,
                path_precision=3
            )

            if output_path.exists() and output_path.stat().st_size > 0:
                logger.info(f"Vectorization complete: {output_path}")
                return output_path
            else:
                logger.error("Output file not created or empty")
                return None

        except Exception as e:
            logger.error(f"Vectorization failed: {e}")
            raise
