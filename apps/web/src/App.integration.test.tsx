import { describe, it, expect } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
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
        <MemoryRouter initialEntries={['/']}>
          <App />
        </MemoryRouter>
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
        <MemoryRouter initialEntries={['/']}>
          <App />
        </MemoryRouter>
      </HelmetProvider>
    )

    // Check for home page content
    expect(screen.getByText(/Let's Talk/i)).toBeInTheDocument()
  })

  it('renders privacy page at /privacy route', async () => {
    render(
      <HelmetProvider>
        <MemoryRouter initialEntries={['/privacy']}>
          <App />
        </MemoryRouter>
      </HelmetProvider>
    )

    await waitFor(() => {
      expect(screen.getByRole('heading', { level: 1, name: /Privacy Policy/i })).toBeInTheDocument()
    })
  })

  it('renders terms page at /terms route', async () => {
    render(
      <HelmetProvider>
        <MemoryRouter initialEntries={['/terms']}>
          <App />
        </MemoryRouter>
      </HelmetProvider>
    )

    await waitFor(() => {
      expect(screen.getByRole('heading', { level: 1, name: /Terms of Service/i })).toBeInTheDocument()
    })
  })

  it('renders security page at /security route', async () => {
    render(
      <HelmetProvider>
        <MemoryRouter initialEntries={['/security']}>
          <App />
        </MemoryRouter>
      </HelmetProvider>
    )

    await waitFor(() => {
      expect(screen.getByRole('heading', { level: 1, name: /Security Standards/i })).toBeInTheDocument()
    })
  })
})
