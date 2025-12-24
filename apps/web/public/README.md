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
