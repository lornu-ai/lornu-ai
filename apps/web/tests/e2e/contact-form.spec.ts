import { test, expect } from '@playwright/test';

test.describe('Contact Form', () => {
	test('should allow the user to fill out the contact form and submit successfully', async ({ page }) => {
		// Listen for console events for debugging
		page.on('console', (msg) => console.log(`Browser Console: ${msg.text()}`));

		// Get bypass secrets from environment (for CI/local testing)
		const rateLimitBypass = process.env.RATE_LIMIT_BYPASS_SECRET;

		// Mock the API endpoint before navigating to the page
		await page.route('/api/contact', async (route) => {
			const request = route.request();
			const requestBody = request.postDataJSON();

			// Verify bypass headers are present when testing
			if (rateLimitBypass) {
				const bypassHeader = request.headers()['x-bypass-rate-limit'];
				console.log('Rate limit bypass header:', bypassHeader ? 'present' : 'missing');
			}

			// Assert that the request body is correct
			expect(requestBody.name).toBe('E2E Test User');
			expect(requestBody.email).toBe('test@example.com');
			expect(requestBody.message).toBe('This is an automated E2E test message.');

			// Fulfill the request with a mock response
			await route.fulfill({
				status: 200,
				contentType: 'application/json',
				body: JSON.stringify({ success: true, message: 'Message sent successfully' }),
			});
		});

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

		// Wait for the success message to be visible
		const successMessage = page.locator('text=Message sent successfully!');
		await expect(successMessage).toBeVisible({ timeout: 10000 });

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
