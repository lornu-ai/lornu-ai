import { test, expect } from '@playwright/test'

const routes = [
  { path: '/privacy', heading: /privacy/i, linkText: 'Privacy' },
  { path: '/terms', heading: /terms/i, linkText: 'Terms' },
  { path: '/security', heading: /security/i, linkText: 'Security' },
]

test.describe('Navigation', () => {
  test('footer links navigate to legal pages', async ({ page }) => {
    await page.goto('/')

    for (const route of routes) {
      await page.getByRole('link', { name: route.linkText }).click()
      await expect(page).toHaveURL(new RegExp(`${route.path}$`))
      await expect(page.getByRole('heading', { name: route.heading })).toBeVisible()
      await page.goBack()
    }
  })
})
