import { test, expect } from '@playwright/test';

test.describe('Synthetic Monitoring', () => {
  test('should verify the main page loads and the health endpoint is ok', async ({ page, request }) => {
    // Check the main page
    await page.goto('/');
    await expect(page).toHaveTitle(/LornuAI/);
    await expect(page.getByRole('heading', { name: 'LornuAI' })).toBeVisible();

    // Check the health endpoint
    const response = await request.get('/api/health');
    expect(response.ok()).toBeTruthy();

    // In a Vite dev environment, the health endpoint will return HTML.
    // We only check for a 200 OK status in this case.
    const contentType = response.headers()['content-type'];
    if (contentType?.includes('application/json')) {
      const json = await response.json();
      expect(json.status).toBe('ok');
    }
  });
});
