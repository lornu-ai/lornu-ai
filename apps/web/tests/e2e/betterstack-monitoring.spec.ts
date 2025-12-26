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
        await page.waitForLoadState('networkidle');

        // Test navigation to Terms page - required critical path
        const termsLink = page.getByRole('link', { name: /terms/i });
        await expect(termsLink).toBeVisible({ timeout: 5000 });
        await termsLink.click();

        await expect(page).toHaveURL(/\/terms/, { timeout: 5000 });
        await expect(page.getByRole('heading', { name: /terms of service/i })).toBeVisible({ timeout: 5000 });

        // Test navigation to Privacy page - required critical path
        await page.goto(PRODUCTION_URL);
        await page.waitForLoadState('networkidle');
        
        const privacyLink = page.getByRole('link', { name: /privacy/i });
        await expect(privacyLink).toBeVisible({ timeout: 5000 });
        await privacyLink.click();
        
        await expect(page).toHaveURL(/\/privacy/, { timeout: 5000 });
        await expect(page.getByRole('heading', { name: /privacy/i })).toBeVisible({ timeout: 5000 });
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

        // Filter to only critical, application errors (not third-party tracking errors)
        const criticalErrors = errors.filter(err => {
            // Allow known non-critical error sources
            if (err.includes('favicon')) return false; // Favicon not found is non-critical
            if (err.includes('AdBlock')) return false; // Ad blocker warnings
            if (err.includes('google-analytics')) return false; // GA errors are non-critical
            if (err.includes('gtag')) return false; // Google tag errors
            if (err.includes('recaptcha') || err.includes('reCAPTCHA')) return false; // ReCAPTCHA errors
            if (err.includes('tracking')) return false; // Third-party tracking
            
            // Report all other errors as they may indicate real application issues
            return true;
        });

        expect(criticalErrors).toHaveLength(0);
    });

    test('Static assets load successfully', async ({ page }) => {
        const failedRequests: string[] = [];

        // Attach listener BEFORE navigation to capture all request failures
        page.on('requestfailed', request => {
            const url = request.url();
            // Track failures for application-critical assets (JS, CSS, images)
            // Exclude third-party tracking and analytics which may fail without affecting app
            if (url.match(/\.(js|css|png|jpg|svg|woff2|woff|ttf)$/) &&
                !url.includes('google') &&
                !url.includes('analytics') &&
                !url.includes('tracking') &&
                !url.includes('facebook') &&
                !url.includes('twitter')) {
                failedRequests.push(url);
            }
        });

        // Navigate to page and wait for all requests to complete
        await page.goto(PRODUCTION_URL);
        await page.waitForLoadState('networkidle');

        // Assert no critical application assets failed to load
        expect(failedRequests).toHaveLength(0);
    });
});
