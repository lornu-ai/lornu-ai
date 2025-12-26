import { test, expect } from '@playwright/test';

test.describe('Contact Form', () => {
	test('should allow the user to fill out the contact form and submit successfully', async ({ page }) => {
		// Mock the API endpoint
		await page.route('/api/contact', async route => {
			await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ success: true }) });
		});

		// Listen for console events for debugging
		page.on('console', (msg) => console.log(`Browser Console: ${ msg.text() } `));

		// Navigate to contact page
		await page.goto('/contact');

		// Handle the cookie consent banner if present
		const acceptButton = page.locator('button:has-text("Accept")');
		if (await acceptButton.isVisible()) {
			await acceptButton.click();
		}

		// Fill out the form
		const nameInput = page.locator('input[name="name"]');
		const emailInput = page.locator('input[name="email"]');
		const messageInput = page.locator('textarea[name="message"]');
		const submitButton = page.locator('button[type="submit"]');

		await nameInput.fill('E2E Test User');
		await emailInput.fill('test@example.com');
		await messageInput.fill('This is an automated E2E test message.');
		await submitButton.click();

		// Wait for the success toast to appear
		const toast = page.locator('[data-sonner-toast]').first();
		await expect(toast).toBeVisible({ timeout: 10000 });
		await expect(toast).toHaveText(/Message sent successfully!/);

		// Verify form was reset
		await expect(nameInput).toHaveValue('');
		await expect(emailInput).toHaveValue('');
		await expect(messageInput).toHaveValue('');
	});

	test('should show validation errors for invalid inputs', async ({ page }) => {
		await page.goto('/contact');

		// Handle the cookie consent banner if present
		const acceptButton = page.locator('button:has-text("Accept")');
		if (await acceptButton.isVisible()) {
			await acceptButton.click();
		}

		const submitButton = page.locator('button[type="submit"]');

		// Try to submit empty form
		await submitButton.click();

		// Should see validation errors
		await expect(page.locator('text=Name must be at least 2 characters.')).toBeVisible();
		await expect(page.locator('text=Invalid email address.')).toBeVisible();
		await expect(page.locator('text=Message must be at least 10 characters.')).toBeVisible();
	});
});
