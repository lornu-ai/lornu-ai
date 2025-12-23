import { describe, it, expect } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { HelmetProvider } from 'react-helmet-async'
import Terms from './Terms'

describe('Terms Page', () => {
  const renderTerms = () => {
    return render(
      <HelmetProvider>
        <BrowserRouter>
          <Terms />
        </BrowserRouter>
      </HelmetProvider>
    )
  }

  it('renders Terms of Service heading', () => {
    renderTerms()
    expect(screen.getByRole('heading', { name: /Terms of Service/i })).toBeInTheDocument()
  })

  it('renders back to home link', () => {
    renderTerms()
    const backButtons = screen.getAllByRole('link', { name: /Back to Home/i })
    expect(backButtons.length).toBeGreaterThan(0)
  })

  it('sets correct page title via SEOHead', async () => {
    renderTerms()
    await waitFor(() => {
      expect(document.title).toBe('Terms of Service | LornuAI')
    })
  })

  it('renders logo in navigation', () => {
    renderTerms()
    const logo = screen.getByLabelText('Lornuai Enterprise AI Logo')
    expect(logo).toBeInTheDocument()
  })

  it('has link to home page', () => {
    renderTerms()
    const homeLink = screen.getByRole('link', { name: /LornuAI home/i })
    expect(homeLink).toHaveAttribute('href', '/')
  })
})
