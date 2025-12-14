import { test, expect } from '@playwright/test'

const routes = [
  { path: '/privacy', mainHeading: /Privacy Policy/i, linkText: 'Privacy' },
  { path: '/terms', mainHeading: /Terms of Service/i, linkText: 'Terms' },
  { path: '/security', mainHeading: /Security Standards/i, linkText: 'Security' },
]

test.describe('Navigation', () => {
  test('footer links navigate to legal pages', async ({ page }) => {
    await page.goto('/')

    for (const route of routes) {
      await page.getByRole('link', { name: route.linkText }).click()
      await expect(page).toHaveURL(new RegExp(`${route.path}$`))
      // Use locator to find the h1 (main heading) specifically
      await expect(page.locator('h1', { hasText: route.mainHeading })).toBeVisible()
      await page.goBack()
    }
  })
})
