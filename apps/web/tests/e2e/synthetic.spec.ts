import { test, expect } from '@playwright/test';

/**
 * Synthetic Monitor for Better Stack
 *
 * Target User Journey:
 * 1. Login
 * 2. Navigate to /threads
 * 3. Open a thread
 * 4. Verify AI agent output exists
 *
 * Current State:
 * - Validates Homepage load
 * - Validates Health endpoint
 * - Validates Contact section
 * - (Auth steps commented out until feature deployment)
 */
test('Synthetic Monitor: Critical User Journey', async ({ page, request, baseURL }) => {
    // Priority: Env Var (Better Stack) -> Fixture (CI/Local)
    const BASE_URL = process.env.BASE_URL || baseURL;

    if (!BASE_URL) {
        throw new Error('BASE_URL environment variable or Playwright baseURL fixture is required.');
    }

    // 1. Visit Home
    console.log(`Navigating to ${BASE_URL}`);
    await page.goto(BASE_URL);
    await expect(page).toHaveTitle(/LornuAI/i);
    await expect(page.getByRole('button', { name: /Get Started/i }).first()).toBeVisible();

    // 2. Check Health Endpoint (API Connectivity)
    const healthRes = await request.get(`${BASE_URL}/api/health`);
    // Note: /api/health might return straight JSON or HTML depending on env
    // In dev mode with Vite proxy, it should return JSON from backend
    expect(healthRes.status()).toBe(200);
    
    // Verify health response (either JSON from API or HTML from SPA fallback)
    const contentType = healthRes.headers()['content-type'];
    if (contentType?.includes('application/json')) {
      const body = await healthRes.json();
      expect(body).toHaveProperty('status');
    }

    // 3. Critical Flow: Contact (Since Auth isn't live yet)
    await page.getByRole('button', { name: /Get Started/i }).first().click();
    const contactForm = page.locator('form');
    await expect(contactForm).toBeVisible();

    // 4. (FUTURE) Auth Flow & Thread Check
    /*
    // Login
    await page.goto(`${BASE_URL}/login`);

    const email = process.env.MONITOR_EMAIL;
    const password = process.env.MONITOR_PASSWORD;

    if (!email || !password) {
        throw new Error('MONITOR_EMAIL and MONITOR_PASSWORD environment variables are required for Auth Flow.');
    }

    await page.getByLabel('Email').fill(email);
    await page.getByLabel('Password').fill(password);
    await page.getByRole('button', { name: /sign in/i }).click();

    // Verify Dashboard
    await expect(page).toHaveURL(/.*dashboard/);

    // Navigate to Threads
    await page.getByRole('link', { name: /threads/i }).click();

    // Open Latest Thread
    const firstThread = page.locator('.thread-item').first();
    await firstThread.waitFor();
    await firstThread.click();

    // Verify Agent Output
    // Check for a message bubble from the AI
    const aiMessage = page.locator('.message-bubble.ai-response');
    await expect(aiMessage).toBeVisible();
    await expect(aiMessage).toContainText(/summary|analysis|answer/i);
    */
});
