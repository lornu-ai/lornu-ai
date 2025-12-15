import { test, expect } from '@playwright/test';

test('should submit the contact form successfully', async ({ page }) => {
  // Mock the API request before navigating to the page
  await page.route('**/api/contact', async (route) => {
    // Fulfill the request with a 200 OK response
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ message: 'Success' }),
    });
  });

  await page.goto('/');

  await page.getByRole('button', { name: 'Contact' }).first().click();

  await page.getByLabel('Name').fill('Test User');
  await page.getByLabel('Email').fill('test@example.com');
  await page.getByLabel('Message').fill('This is a test message.');

  await page.getByRole('button', { name: 'Send Message' }).click();

  await expect(page.getByText('Message sent! We\'ll be in touch soon.')).toBeVisible();
});
