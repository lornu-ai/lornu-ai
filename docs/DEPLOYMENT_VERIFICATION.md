# Deployment Verification Guide

**Status:** Active
**Last Updated:** 2025-12-15

## Overview

This guide outlines the two-tier approach for verifying deployments: a fast API health check and a comprehensive E2E smoke test.

## Existing Monitoring

### Cloudflare Performance Reporting

Performance monitoring is already configured:
- **Dashboard:** [Cloudflare Performance](https://dash.cloudflare.com/YOUR_ACCOUNT_ID/lornu.ai/speed/test/lornu.ai%2F/history/desktop/us-central1)
- **Tracks:** Core Web Vitals, page load times, performance scores
- **Location:** Desktop, US Central

**Note:** This complements but doesn't replace uptime monitoring. Use both for comprehensive coverage.

## Two-Tier Verification Strategy

### Tier 1: API Health Check (Fastest - < 1 second)

**Purpose:** Verify the Cloudflare Worker runtime is alive and responding.

**Implementation:**
```bash
# Simple curl command
curl -f https://lornu.ai/api/health

# Expected response:
# {"status":"ok"}
# HTTP/2 200
```

**When to Use:**
- Immediately after deployment
- In CI/CD pipelines for fast feedback
- External monitoring (UptimeRobot, etc.)

**Exit Code:**
- `0` = Success (Worker is alive)
- Non-zero = Failure (Worker is down)

### Tier 2: E2E Smoke Test (Comprehensive - ~10-15 seconds)

**Purpose:** Verify the full stack (Frontend, Worker, API, UI rendering) is integrated and functional.

**Implementation:**
```bash
# Run Playwright smoke test
cd apps/web
bun run test:e2e:smoke

# Or with custom base URL
PLAYWRIGHT_BASE_URL=https://lornu.ai bun run test:e2e:smoke
```

**What It Tests:**
1. Home page loads successfully
2. Contact form is accessible and functional
3. Health endpoint is accessible
4. Page navigation works

**When to Use:**
- After successful health check
- Before marking deployment as complete
- In CI/CD pipelines for high-confidence verification
- Daily production monitoring

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Verify Deployment

on:
  workflow_dispatch:
  push:
    branches: [main]

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Bun
        uses: oven-sh/setup-bun@v1
        with:
          bun-version: latest

      - name: Install dependencies
        run: |
          cd apps/web
          bun install
          bunx playwright install --with-deps chromium

      - name: Health Check (Tier 1)
        run: |
          curl -f https://lornu.ai/api/health || exit 1

      - name: E2E Smoke Test (Tier 2)
        run: |
          cd apps/web
          bun run test:e2e:smoke
        env:
          PLAYWRIGHT_BASE_URL: https://lornu.ai
```

### Cloudflare Git Integration

Since Cloudflare handles deployment automatically, add a post-deployment verification step:

1. **Option A: External Monitoring**
   - Use UptimeRobot or similar service
   - Configure to ping `/api/health` after deployment
   - Set up alerts for failures

2. **Option B: GitHub Actions Post-Deploy**
   - Trigger workflow after Cloudflare deployment completes
   - Run health check and smoke test
   - Report results back to PR/issue

3. **Option C: Manual Verification**
   - Run verification commands manually after deployment
   - Document in deployment checklist

## Quick Reference

### Health Check Commands

```bash
# Basic check
curl -f https://lornu.ai/api/health

# With verbose output
curl -v https://lornu.ai/api/health

# Check status code only
curl -s -o /dev/null -w "%{http_code}" https://lornu.ai/api/health
# Expected: 200
```

### E2E Test Commands

```bash
# Run smoke test (production)
cd apps/web
bun run test:e2e:smoke

# Run smoke test (local)
PLAYWRIGHT_BASE_URL=http://localhost:5173 bun run test:e2e:smoke

# Run all E2E tests
bun run test:e2e

# Run with UI (interactive)
bun run test:e2e:ui
```

## Verification Checklist

After each deployment:

- [ ] **Tier 1: Health Check**
  - [ ] `curl -f https://lornu.ai/api/health` returns 200
  - [ ] Response body is `{"status":"ok"}`

- [ ] **Tier 2: E2E Smoke Test**
  - [ ] Home page loads
  - [ ] Contact form works
  - [ ] Navigation works
  - [ ] All tests pass

- [ ] **Manual Spot Check**
  - [ ] Visit `https://lornu.ai` in browser
  - [ ] Verify page renders correctly
  - [ ] Test contact form submission
  - [ ] Check browser console for errors

## Troubleshooting

### Health Check Fails

**Symptoms:**
- `curl` returns non-zero exit code
- HTTP status is not 200
- Connection timeout

**Investigation:**
1. Check Cloudflare Dashboard for worker errors
2. Review worker logs
3. Verify deployment completed successfully
4. Check for recent code changes

**Resolution:**
- Rollback if recent deployment
- Check worker configuration
- Verify environment variables
- Restart worker if needed

### E2E Tests Fail

**Symptoms:**
- Tests timeout
- Elements not found
- Form submission fails

**Investigation:**
1. Check if health check passes first
2. Review test screenshots (in `test-results/`)
3. Verify base URL is correct
4. Check for JavaScript errors in browser console

**Resolution:**
- Fix underlying issue (not test)
- Update test selectors if UI changed
- Increase timeouts if network is slow
- Verify deployment completed before running tests

## Best Practices

1. **Always Run Tier 1 First**
   - Fast feedback (< 1 second)
   - Catches obvious failures immediately

2. **Run Tier 2 After Tier 1 Passes**
   - Higher confidence verification
   - Catches integration issues

3. **Use in CI/CD**
   - Automate verification
   - Prevent broken deployments
   - Fast feedback loop

4. **Monitor Continuously**
   - External monitoring (UptimeRobot)
   - Daily smoke test runs
   - Alert on failures

## Related Documentation

- [E2E Testing Guide](./E2E_TESTING.md)
- [Uptime Monitoring Setup](./UPTIME_MONITORING_SETUP.md)
- [Issue #66](https://github.com/lornu-ai/lornu-ai/issues/66)
