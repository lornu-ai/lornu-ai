# Public Assets Directory

This directory contains static assets served directly by the web server.

## Favicon Files

**Required:** Generate favicon files from the logo and place them here.

### Expected Files:
- `favicon.ico` - Standard favicon (16x16, 32x32, 48x48)
- `favicon-16x16.png` - 16x16 PNG favicon
- `favicon-32x32.png` - 32x32 PNG favicon  
- `apple-touch-icon.png` - 180x180 PNG for iOS devices

### Generation Tools:
- Online: https://realfavicongenerator.net/
- Online: https://favicon.io/
- CLI: `npx @vitejs/plugin-legacy` (not needed, use online tools)

### Steps:
1. Download logo from Google Drive (see issue #10)
2. Use an online favicon generator with the logo
3. Place all generated files in this directory
4. Update `index.html` favicon links (already prepared)

### Logo Source:
Google Drive: https://drive.google.com/file/d/1VwCBEDtaA-Rab1REXJY7Ialp8dQXkyMr/view?usp=sharing

