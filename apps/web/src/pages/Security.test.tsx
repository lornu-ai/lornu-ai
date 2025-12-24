import { describe, it, expect } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { HelmetProvider } from 'react-helmet-async'
import Security from './Security'
import { ThemeProvider } from '@/contexts/ThemeContext'

describe('Security Page', () => {
  const renderSecurity = () => {
    return render(
      <HelmetProvider>
        <ThemeProvider>
          <BrowserRouter>
            <Security />
          </BrowserRouter>
        </ThemeProvider>
      </HelmetProvider>
    )
  }

  it('renders Security Standards heading', () => {
    renderSecurity()
    expect(screen.getByRole('heading', { name: /Security Standards/i })).toBeInTheDocument()
  })

  it('renders back to home link', () => {
    renderSecurity()
    const backButtons = screen.getAllByRole('link', { name: /Back to Home/i })
    expect(backButtons.length).toBeGreaterThan(0)
  })

  it('sets correct page title via SEOHead', async () => {
    renderSecurity()
    await waitFor(() => {
      expect(document.title).toBe('Security Standards | LornuAI')
    })
  })

  it('renders logo in navigation', () => {
    renderSecurity()
    const logo = screen.getByAltText('Lornuai Enterprise AI Logo')
    expect(logo).toBeInTheDocument()
  })

  it('has link to home page', () => {
    renderSecurity()
    const homeLink = screen.getByRole('link', { name: /LornuAI home/i })
    expect(homeLink).toHaveAttribute('href', '/')
  })
})
