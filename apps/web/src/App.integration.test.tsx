import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { HelmetProvider } from 'react-helmet-async'
import App from './App'

describe('App - Navigation Integration', () => {
  const routes = [
    { path: '/privacy', mainHeading: /Privacy Policy/i, linkText: 'Privacy' },
    { path: '/terms', mainHeading: /Terms of Service/i, linkText: 'Terms' },
    { path: '/security', mainHeading: /Security Standards/i, linkText: 'Security' },
  ]

  it('renders footer links for legal pages', () => {
    render(
      <HelmetProvider>
        <App />
      </HelmetProvider>
    )

    // Verify all footer links are present
    for (const route of routes) {
      const link = screen.getByRole('link', { name: route.linkText })
      expect(link).toBeInTheDocument()
      expect(link).toHaveAttribute('href', route.path)
    }
  })

  it('renders home page by default', () => {
    render(
      <HelmetProvider>
        <App />
      </HelmetProvider>
    )

    // Check for home page content
    expect(screen.getByText(/Let's Talk/i)).toBeInTheDocument()
  })

  // Note: Testing different routes requires navigation, which is better suited for E2E tests
  // These integration tests verify the app structure and default route
})
