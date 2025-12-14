import { describe, it, expect } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { HelmetProvider } from 'react-helmet-async'
import Privacy from './Privacy'

describe('Privacy Page', () => {
  const renderPrivacy = () => {
    return render(
      <HelmetProvider>
        <BrowserRouter>
          <Privacy />
        </BrowserRouter>
      </HelmetProvider>
    )
  }

  it('renders Privacy Policy heading', () => {
    renderPrivacy()
    expect(screen.getByRole('heading', { level: 1, name: /Privacy Policy/i })).toBeInTheDocument()
  })

  it('renders back to home link', () => {
    renderPrivacy()
    const backButtons = screen.getAllByRole('link', { name: /Back to Home/i })
    expect(backButtons.length).toBeGreaterThan(0)
  })

  it('sets correct page title via SEOHead', async () => {
    renderPrivacy()
    await waitFor(() => {
      expect(document.title).toBe('Privacy Policy | LornuAI')
    })
  })

  it('renders logo in navigation', () => {
    renderPrivacy()
    const logo = screen.getByAltText('Lornuai Enterprise AI Logo')
    expect(logo).toBeInTheDocument()
  })

  it('has link to home page', () => {
    renderPrivacy()
    const homeLink = screen.getByRole('link', { name: /LornuAI home/i })
    expect(homeLink).toHaveAttribute('href', '/')
  })
})
