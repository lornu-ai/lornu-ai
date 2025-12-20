import { test, expect } from '@playwright/test';

test.describe('Smoke Test', () => {
	test('should allow the user to fill out the contact form and mock the submission', async ({ page }) => {
		// Listen for all console events and log them to the test output
		page.on('console', (msg) => console.log(`Browser Console: ${msg.text()}`));

		// Mock the API endpoint before navigating to the page
		await page.route('/api/contact', async (route) => {
			const requestBody = route.request().postDataJSON();

			// Assert that the request body is correct
			expect(requestBody.name).toBe('E2E Test User');
			expect(requestBody.email).toBe('test@example.com');
			expect(requestBody.message).toBe('This is an automated E2E smoke test message.');

			// Fulfill the request with a mock response
			await route.fulfill({
				status: 200,
				contentType: 'application/json',
				body: JSON.stringify({ success: true, message: 'Message sent successfully' }),
			});
		});

		await page.goto('/contact');

		// Handle the cookie consent banner
		const acceptButton = page.locator('button:has-text("Accept")');
		await acceptButton.click();

		const nameInput = page.locator('input[name="name"]');
		const emailInput = page.locator('input[name="email"]');
		const messageInput = page.locator('textarea[name="message"]');
		const submitButton = page.locator('button[type="submit"]');

		await nameInput.fill('E2E Test User');
		await emailInput.fill('test@example.com');
		await messageInput.fill('This is an automated E2E smoke test message.');
		await submitButton.click();

		// Wait for the success message to be visible
		const successMessage = page.locator('text=Message sent successfully!');
		await expect(successMessage).toBeVisible();
	});
});
