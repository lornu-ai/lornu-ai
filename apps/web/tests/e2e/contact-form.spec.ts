import { test, expect } from '@playwright/test'

test.describe('Contact form', () => {
  test('submits successfully with mocked API', async ({ page }) => {
    await page.route('**/api/contact', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ success: true, message: 'Message sent successfully' }),
      })
    })

    await page.goto('/')
    await page.getByLabel('Name').fill('Jane Doe')
    await page.getByLabel('Email').fill('jane@example.com')
    await page.getByLabel('Message').fill('Looking forward to working with you!')

    await page.getByRole('button', { name: /send message/i }).click()

    await expect(page.getByText("Message sent! We'll be in touch soon.")).toBeVisible()
  })
})
