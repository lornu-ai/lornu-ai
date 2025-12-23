# Brand Assets Directory

This directory contains the official Lornu AI branding assets.

## Logo Asset

The new logo should be placed here:

- **File:** `lornu-ai-final-clear-bg.png`
- **Format:** PNG (optimized)
- **Size:** Keep below 500KB for optimal performance
- **Source:** [Google Drive](https://drive.google.com/file/d/1mmpkYJHyucyz2SD94mvGUrQkHtO66hVN/view?usp=drive_link)

> **Note:** For improved CI/CD automation and developer experience, consider using [Git LFS (Large File Storage)](https://git-lfs.github.com/) for managing large brand assets in the future. This would eliminate manual download steps and ensure consistent asset availability across all environments.

### Setup Instructions

1. Download `lornu-ai-final-clear-bg.png` from the Google Drive link above
2. Optimize the image (reduce to ~300-500KB using compression tools like TinyPNG or ImageMagick)
3. Place the optimized PNG in this directory
4. The Logo component will automatically use it

### Development Notes

- The logo PNG should have a transparent background for flexibility
- Keep aspect ratio consistent across different sizes
- The component uses `object-contain` to maintain aspect ratio scaling
- Supports responsive sizing via the Logo component's `size` prop (sm, md, lg)
