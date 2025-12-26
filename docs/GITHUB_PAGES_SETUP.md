# GitHub Pages Setup for Monitoring Dashboard

## Quick Setup

After merging PR #339, you need to enable GitHub Pages in the repository:

### 1. Enable GitHub Pages

1. Go to: https://github.com/lornu-ai/lornu-ai/settings/pages
2. Under "Source", select: **Deploy from a branch**
3. Select branch: **gh-pages**
4. Select folder: **/ (root)**
5. Click **Save**

### 2. Wait for Deployment

The first deployment takes 2-3 minutes. Once complete, your monitoring dashboard will be available at:

**🔗 https://lornu-ai.github.io/lornu-ai/**

### 3. Access the Dashboard

- **Main Page**: https://lornu-ai.github.io/lornu-ai/
  - Shows system status at a glance
  - Links to latest test report
  - Auto-updates every 5 minutes

- **Latest Test Report**: https://lornu-ai.github.io/lornu-ai/latest/
  - Full Playwright HTML report
  - Test results with screenshots
  - Detailed error messages

## What Gets Published

Every time the monitoring workflow runs (every 5 minutes):
1. Playwright tests execute
2. HTML report is generated
3. Report is published to GitHub Pages
4. Landing page updates with current status

## Custom Domain (Optional)

To host at `status.lornu.ai` instead:

### Option A: CNAME to GitHub Pages

1. Add CNAME record in your DNS:
   ```
   status.lornu.ai  CNAME  lornu-ai.github.io
   ```

2. In GitHub repository settings → Pages → Custom domain:
   - Enter: `status.lornu.ai`
   - Click **Save**

3. Wait for DNS propagation (5-10 minutes)

4. Enable "Enforce HTTPS"

### Option B: Cloudflare Proxy (More Control)

1. Add CNAME in Cloudflare DNS:
   ```
   status  CNAME  lornu-ai.github.io  (Proxy enabled)
   ```

2. In GitHub Pages settings:
   - Custom domain: `status.lornu.ai`

3. In Cloudflare:
   - Page Rules → Cache Everything
   - SSL/TLS → Full

## Features

✅ **Auto-updates**: New report every 5 minutes
✅ **No download**: View directly in browser
✅ **Mobile-friendly**: Responsive design
✅ **Screenshots**: Included on test failures
✅ **History**: Previous reports in artifacts (30 days)
✅ **Free**: No hosting costs

## Troubleshooting

### GitHub Pages Not Showing

**Issue**: 404 error when visiting the URL
**Solution**:
- Verify `gh-pages` branch exists: https://github.com/lornu-ai/lornu-ai/tree/gh-pages
- Check Pages settings are correct
- Wait 2-3 minutes after first deployment
- Clear browser cache

### Report Not Updating

**Issue**: Monitoring workflow runs but report doesn't update
**Solution**:
- Check workflow logs for errors
- Verify `peaceiris/actions-gh-pages` step succeeded
- Check `gh-pages` branch commit history

### Custom Domain Not Working

**Issue**: CNAME configured but gets 404
**Solution**:
- Verify DNS propagation: `dig status.lornu.ai`
- Check GitHub Pages custom domain settings
- Ensure HTTPS is enabled (may take time for cert)
- Verify no conflicting DNS records

## Maintenance

### Update Landing Page

To customize the status page, edit in the workflow:
```yaml
# .github/workflows/synthetic-monitoring.yml
# Search for: "Create index page with links to all reports"
```

Then modify the HTML in the `cat > gh-pages/index.html` block.

### Change Report Retention

Reports are kept in the `gh-pages` branch. To keep history:

```yaml
# In workflow, change:
keep_files: false  # Overwrites everything

# To:
keep_files: true   # Keeps old reports
```

Then organize reports by date/run number.

## Access Control

### Public Access (Current)

Anyone can view: https://lornu-ai.github.io/lornu-ai/

### Private Access (Alternative)

To restrict access:

1. Make repository private
2. GitHub Pages will require authentication
3. Only org members can view

**OR** host reports in Cloud Storage with signed URLs instead.

## Next Steps

1. ✅ Merge PR #339
2. ✅ Enable GitHub Pages (see above)
3. ✅ Visit https://lornu-ai.github.io/lornu-ai/
4. ✅ (Optional) Configure custom domain

---

**Live Dashboard**: https://lornu-ai.github.io/lornu-ai/ (after setup)
**Repository**: https://github.com/lornu-ai/lornu-ai
**Workflow**: https://github.com/lornu-ai/lornu-ai/actions/workflows/synthetic-monitoring.yml
