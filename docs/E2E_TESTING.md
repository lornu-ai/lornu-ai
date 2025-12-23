# E2E Testing with Playwright

**Status:** Active
**Last Updated:** 2025-12-15

## Overview

This project uses **Playwright** for End-to-End (E2E) testing to verify the full stack (Frontend, Worker, API) is integrated and functional.

## Quick Start

### Install Dependencies

```bash
cd apps/web
bun install
bunx playwright install --with-deps chromium
```

### Run Tests

```bash
# Run all E2E tests
bun run test:e2e

# Run smoke test only (fast, CI-friendly)
bun run test:e2e:smoke

# Run with UI (interactive)
bun run test:e2e:ui
```

## Test Structure

### Smoke Test (`tests/e2e/smoke-test.spec.ts`)

The smoke test verifies core functionality:

1. **Home Page Loads**
   - Verifies page title
   - Checks key elements are visible
   - Validates navigation

2. **Contact Form Works**
   - Verifies form is accessible
   - Tests form submission
   - Confirms success message appears

3. **Health Endpoint**
   - Direct API test
   - Verifies `/api/health` returns 200 OK

4. **Page Navigation**
   - Tests routing between pages
   - Verifies page content loads

## Configuration

### Base URL

Tests run against production by default (`https://lornu.ai`). To test locally:

```bash
# Set environment variable
PLAYWRIGHT_BASE_URL=http://localhost:5173 bun run test:e2e
```

Or update `playwright.config.ts`:

```typescript
use: {
  baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:5173',
}
```

### CI/CD Integration

The smoke test is designed to run in CI/CD pipelines:

```yaml
# Example GitHub Actions step
- name: Run E2E Smoke Test
  run: |
    cd apps/web
    bun run test:e2e:smoke
  env:
    PLAYWRIGHT_BASE_URL: https://lornu.ai
```

## Test Strategy

### Two-Tier Approach

1. **API Health Check** (`/api/health`)
   - Fastest check (< 1 second)
   - Verifies Worker runtime is alive
   - Use in CI/CD immediately after deployment

2. **E2E Smoke Test** (Playwright)
   - Full stack verification
   - Tests actual user flow
   - Higher confidence, takes longer (~10-15 seconds)

### When to Run

- **After Deployment:** Run smoke test to verify deployment success
- **Before Release:** Run full E2E suite
- **On Schedule:** Daily smoke tests for production monitoring
- **On PR:** Run smoke test for critical changes

## Adding New Tests

### Example: Test New Feature

```typescript
import { test, expect } from '@playwright/test';

test('New feature works', async ({ page }) => {
  await page.goto('/');

  // Interact with feature
  await page.getByRole('button', { name: 'New Feature' }).click();

  // Verify result
  await expect(page.getByText('Feature Result')).toBeVisible();
});
```

### Best Practices

1. **Use Semantic Selectors:**
   - Prefer `getByRole`, `getByLabel`, `getByText`
   - Avoid `getByTestId` unless necessary

2. **Wait for Elements:**
   - Use `toBeVisible()` with timeout
   - Don't use `waitForTimeout()` (flaky)

3. **Test User Flows:**
   - Test what users actually do
   - Don't test implementation details

4. **Keep Tests Fast:**
   - Smoke tests should complete in < 30 seconds
   - Use `test:e2e:smoke` for CI/CD

## Troubleshooting

### Tests Fail Locally

1. **Check Base URL:**
   ```bash
   # Ensure local dev server is running
   bun run dev

   # Run tests against local
   PLAYWRIGHT_BASE_URL=http://localhost:5173 bun run test:e2e
   ```

2. **Check Browser Installation:**
   ```bash
   bunx playwright install --with-deps chromium
   ```

3. **View Test Results:**
   ```bash
   bunx playwright show-report
   ```

### Tests Fail in CI

1. **Check Environment:**
   - Verify `PLAYWRIGHT_BASE_URL` is set correctly
   - Ensure deployment completed before tests run

2. **Check Timeouts:**
   - Increase timeout for slow networks
   - Use `test.setTimeout()` for specific tests

3. **Check Screenshots:**
   - Screenshots are saved on failure
   - Review in CI artifacts or `test-results/`

## Future Enhancements

- [ ] Add RAG search E2E test (when feature is implemented)
- [ ] Add visual regression testing
- [ ] Add performance testing
- [ ] Add accessibility testing
- [ ] Add mobile device testing

## Resources

- [Playwright Documentation](https://playwright.dev)
- [Playwright Best Practices](https://playwright.dev/docs/best-practices)
- [Issue #66](https://github.com/lornu-ai/lornu-ai/issues/66)
