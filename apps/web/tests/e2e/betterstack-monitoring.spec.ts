import { test, expect } from '@playwright/test';

/**
 * BetterStack Synthetic Monitoring - Production Health Check
 *
 * This test verifies that the production application (https://lornu.ai) is healthy:
 * 1. Home page loads successfully
 * 2. API health endpoint responds correctly
 * 3. Critical navigation works
 * 4. Contact form is accessible
 *
 * To use with BetterStack:
 * 1. Go to https://uptime.betterstack.com/team/t483057/monitors
 * 2. Create a new monitor → "Alert us when: Playwright scenario fails"
 * 3. Copy this file's contents into the scenario editor
 * 4. Set monitoring frequency (e.g., every 5 minutes)
 * 5. Configure alert policy for on-call team
 */

test.describe('Production Health - Synthetic Monitoring', () => {
    // Set a base URL for production
    const PRODUCTION_URL = process.env.PRODUCTION_URL || 'https://lornu.ai';

    test('Home page loads and renders correctly', async ({ page }) => {
        // Navigate to production homepage
        await page.goto(PRODUCTION_URL);

        // Verify page loads within reasonable time
        await expect(page).toHaveTitle(/LornuAI/i, { timeout: 10000 });

        // Verify critical elements are visible
        await expect(page.getByRole('heading', { name: /LornuAI/i })).toBeVisible();

        // Verify navigation is present
        const nav = page.getByRole('navigation');
        await expect(nav).toBeVisible();

        // Take a screenshot for debugging if needed
        await page.screenshot({ path: 'home-page.png', fullPage: false });
    });

    test('API health endpoint responds correctly', async ({ request }) => {
        // Test the health endpoint directly
        const response = await request.get(`${PRODUCTION_URL}/api/health`);

        // Verify status code
        expect(response.status()).toBe(200);

        // Verify JSON response
        const body = await response.json();
        expect(body).toHaveProperty('status', 'ok');
        expect(body).toHaveProperty('service', 'api');
    });

    test('Critical navigation paths work', async ({ page }) => {
        await page.goto(PRODUCTION_URL);

        // Test navigation to Terms page
        const termsLink = page.getByRole('link', { name: /terms/i });
        await termsLink.click();

        await expect(page).toHaveURL(/\/terms/, { timeout: 5000 });
        await expect(page.getByRole('heading', { name: /terms of service/i })).toBeVisible();

        // Test navigation to Privacy page
        await page.goto(PRODUCTION_URL);
        const privacyLink = page.getByRole('link', { name: /privacy/i });

        if (await privacyLink.isVisible()) {
            await privacyLink.click();
            await expect(page).toHaveURL(/\/privacy/, { timeout: 5000 });
            await expect(page.getByRole('heading', { name: /privacy/i })).toBeVisible();
        }
    });

    test('Contact form is accessible', async ({ page }) => {
        await page.goto(PRODUCTION_URL);

        // Scroll to contact section
        const contactSection = page.locator('#contact');
        await contactSection.scrollIntoViewIfNeeded();

        // Verify form inputs are visible
        const nameInput = page.getByLabel(/name/i).or(page.getByPlaceholder(/name/i));
        const emailInput = page.getByLabel(/email/i).or(page.getByPlaceholder(/email/i));
        const messageInput = page.getByLabel(/message/i).or(page.getByPlaceholder(/message/i));

        await expect(nameInput).toBeVisible();
        await expect(emailInput).toBeVisible();
        await expect(messageInput).toBeVisible();

        // Verify submit button is present
        const submitButton = page.getByRole('button', { name: /send|submit/i });
        await expect(submitButton).toBeVisible();
        await expect(submitButton).toBeEnabled();
    });

    test('Page loads without JavaScript errors', async ({ page }) => {
        const errors: string[] = [];

        // Capture console errors
        page.on('console', msg => {
            if (msg.type() === 'error') {
                errors.push(msg.text());
            }
        });

        // Capture page errors
        page.on('pageerror', error => {
            errors.push(error.message);
        });

        await page.goto(PRODUCTION_URL);

        // Wait for page to fully load
        await page.waitForLoadState('networkidle');

        // Assert no critical errors occurred
        const criticalErrors = errors.filter(err =>
            !err.includes('favicon') && // Ignore favicon errors
            !err.includes('AdBlock') // Ignore ad blocker warnings
        );

        expect(criticalErrors).toHaveLength(0);
    });

    test('Static assets load successfully', async ({ page }) => {
        await page.goto(PRODUCTION_URL);

        // Wait for all network requests to complete
        await page.waitForLoadState('networkidle');

        // Verify no failed requests for critical assets
        const failedRequests: string[] = [];

        page.on('requestfailed', request => {
            const url = request.url();
            // Track failures for JS, CSS, and images
            if (url.match(/\.(js|css|png|jpg|svg|woff2)$/)) {
                failedRequests.push(url);
            }
        });

        // Reload to capture failures
        await page.reload();
        await page.waitForLoadState('networkidle');

        // Assert no critical assets failed to load
        expect(failedRequests).toHaveLength(0);
    });
});
