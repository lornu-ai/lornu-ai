# BetterStack Synthetic Monitoring Setup Guide

This guide explains how to configure Playwright-based synthetic monitoring for lornu.ai using BetterStack (Better Uptime).

## Overview

We've created a comprehensive Playwright test suite specifically designed for production monitoring. This allows BetterStack to:
- Simulate real user interactions on https://lornu.ai
- Verify API health endpoints
- Test critical navigation paths
- Monitor for JavaScript errors
- Ensure static assets load correctly

## Setup Instructions

### 1. Create a Playwright Monitor in BetterStack

1. Navigate to: https://uptime.betterstack.com/team/t483057/monitors
2. Click **"Create monitor"**
3. Select: **"Alert us when: Playwright scenario fails"**

### 2. Configure the Monitor

**Basic Settings:**
- **Monitor Name**: `lornu.ai Production Health Check`
- **Frequency**: Every 5 minutes (recommended)
- **Locations**: Select multiple regions for geographic coverage
  - US East
  - US West
  - Europe
  - Asia Pacific (if applicable)

### 3. Add the Playwright Scenario

Copy the contents of `apps/web/tests/e2e/betterstack-monitoring.spec.ts` into the BetterStack scenario editor.

**Alternatively**, use this simplified single-test version for BetterStack:

```typescript
import { test, expect } from '@playwright/test';

test('Production health check', async ({ page, request }) => {
  const PRODUCTION_URL = 'https://lornu.ai';

  // 1. Test API health endpoint
  const apiResponse = await request.get(`${PRODUCTION_URL}/api/health`);
  expect(apiResponse.status()).toBe(200);
  const apiBody = await apiResponse.json();
  expect(apiBody).toHaveProperty('status', 'ok');

  // 2. Test home page loads
  await page.goto(PRODUCTION_URL);
  await expect(page).toHaveTitle(/LornuAI/i, { timeout: 10000 });
  await expect(page.getByRole('heading', { name: /LornuAI/i })).toBeVisible();

  // 3. Test contact form is accessible
  const contactSection = page.locator('#contact');
  await contactSection.scrollIntoViewIfNeeded();
  await expect(page.getByLabel(/name/i).or(page.getByPlaceholder(/name/i))).toBeVisible();
  await expect(page.getByLabel(/email/i).or(page.getByPlaceholder(/email/i))).toBeVisible();

  console.log('✓ All health checks passed');
});
```

### 4. Configure Environment Variables (Optional)

If you need to test authenticated flows or use secrets:

1. Go to **Monitors** → Select your monitor → **Configure** → **Advanced settings** → **Environment variables**
2. Add any required variables:
   - `PRODUCTION_URL` (default: `https://lornu.ai`)
   - `API_KEY` (if needed for authenticated endpoints)

Access them in your script: `process.env.YOUR_VARIABLE_NAME`

### 5. Set Up Alert Policy

1. **On-Call Schedule**: Configure who gets notified
2. **Escalation**: Set up escalation rules (e.g., alert manager after 2 failed checks)
3. **Notification Channels**:
   - Email
   - Slack (recommended)
   - PagerDuty
   - Webhook

### 6. Configure Incident Settings

**Failure Threshold:**
- Fail after: **2 consecutive failures** (recommended to avoid false positives)
- Check frequency: **Every 5 minutes**

**Recovery:**
- Consider recovered after: **1 successful check**

### 7. Test Your Monitor

1. Click **"Run test"** in the BetterStack UI
2. Verify all checks pass
3. Review the execution log and screenshots
4. If failures occur, investigate and fix before enabling alerts

## What Gets Monitored

Our Playwright scenario checks:

### ✅ API Health
- `/api/health` returns 200 OK
- Response includes `{"status": "ok", "service": "api"}`

### ✅ Frontend Availability
- Home page loads within 10 seconds
- Title contains "LornuAI"
- Main heading is visible

### ✅ Critical User Flows
- Navigation to Terms page works
- Navigation to Privacy page works
- Contact form is accessible and functional

### ✅ Error Detection
- No JavaScript console errors
- No failed asset loads (.js, .css, images)
- No page crashes

## Viewing Incident Reports

When a check fails, BetterStack creates an incident:
- URL: https://uptime.betterstack.com/team/t483057/incidents/
- Includes:
  - Screenshots of failures
  - Console logs
  - Network traces
  - Timeline of events

## Running Tests Locally

To test the monitoring script locally before deploying:

```bash
cd apps/web

# Run the BetterStack monitoring suite
PLAYWRIGHT_BASE_URL=https://lornu.ai bun run test:e2e tests/e2e/betterstack-monitoring.spec.ts

# Or test against localhost/staging
PLAYWRIGHT_BASE_URL=http://localhost:5174 bun run test:e2e tests/e2e/betterstack-monitoring.spec.ts
```

## Troubleshooting

### Common Issues

**Issue**: Monitor reports failures but the site is accessible
- **Solution**: Check if the test is too strict. Review the timeout values (currently 10s for page loads).

**Issue**: "Cannot read properties of undefined" error
- **Solution**: The site may be experiencing the React chunk loading issue. Verify PR #333 is merged.

**Issue**: Contact form test fails
- **Solution**: Verify the form selector hasn't changed. Update locators in the test if needed.

**Issue**: Tests pass locally but fail in BetterStack
- **Solution**: BetterStack runs from different geographic locations. Test network latency and adjust timeouts.

## Best Practices

1. **Start Simple**: Begin with a basic health check, then add more complex scenarios
2. **Use Realistic Timeouts**: Production may be slower than localhost (use 10s+ for initial loads)
3. **Monitor from Multiple Regions**: Ensures global availability
4. **Set Proper Failure Thresholds**: Use 2+ consecutive failures to avoid false positives
5. **Keep Tests Fast**: Each test should complete in under 30 seconds
6. **Document Expected Behavior**: Comment your tests so on-call engineers understand what's being checked

## Integration with CI/CD

The same test suite runs in GitHub Actions:

```yaml
# .github/workflows/web-ci.yml
- name: E2E Tests
  run: bun run test:e2e
  env:
    PLAYWRIGHT_BASE_URL: http://localhost:5174
```

This ensures:
- Tests are validated before deployment
- Production monitoring reflects actual application behavior

## Status Page Integration

BetterStack can automatically update a status page:
1. Go to **Status Pages** in BetterStack
2. Create a new status page for lornu.ai
3. Link the Playwright monitor to the status page
4. Share the status page URL with users: `https://status.lornu.ai` (configure DNS CNAME)

## Additional Resources

- [BetterStack Playwright Docs](https://docs.betterstack.com/uptime/monitors/playwright/)
- [Playwright Testing Guide](https://playwright.dev/docs/intro)
- [Our E2E Test Suite](./tests/e2e/)

## Support

For issues with BetterStack configuration:
- Dashboard: https://uptime.betterstack.com/team/t483057
- Email: support@betterstack.com
- Docs: https://docs.betterstack.com
