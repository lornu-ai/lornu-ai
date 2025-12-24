# Public Assets Directory

This directory contains static assets served directly by the web server.

## Favicon Files

### Current Status:
- ✅ `favicon.ico` - Standard favicon (generated from the primary logo asset)
- ✅ `apple-touch-icon.png` - 180x180 PNG for iOS devices

### Optional Additional Files (for enhanced browser/app support):
- `favicon-16x16.png` - 16x16 PNG favicon (optional, for modern browsers)
- `favicon-32x32.png` - 32x32 PNG favicon (optional, for modern browsers)

**Note:** The basic `favicon.ico` is sufficient for most use cases. Additional PNG favicons and Apple touch icons can be added later for enhanced mobile/browser support.

### Generation Tools (if generating additional favicons):
- Online: https://realfavicongenerator.net/
- Online: https://favicon.io/

### Steps (for additional favicons only):
1. Use the brand PNG source as input
2. Use an online favicon generator to create PNG variants
3. Place generated files in this directory
4. Update `index.html` favicon links if needed

## "Proper" Favicon Creation Guide
**(Recorded for later implementation)**

To create a professional, multi-device favicon suite:

1.  **Source Material**: Start with a high-resolution SVG or 512x512 PNG (e.g., `src/assets/logo.svg`).
2.  **Generation**: Use a tool like [RealFaviconGenerator](https://realfavicongenerator.net/) to generate the full suite:
    *   `favicon.ico` (16x16, 32x32, 48x48)
    *   `favicon.svg` (Modern)
    *   `apple-touch-icon.png` (180x180 for iOS)
    *   `icon-192.png` & `icon-512.png` (Android/PWA)
3.  **Implementation**:
    *   Place files in `apps/web/public/`.
    *   Update `index.html` `<head>`:
        ```html
        <link rel="icon" href="/favicon.ico" sizes="any">
        <link rel="icon" href="/logo.svg" type="image/svg+xml">
        <link rel="apple-touch-icon" href="/apple-touch-icon.png">
        <link rel="manifest" href="/manifest.json">
        ```
