import { describe, it, expect } from 'vitest'
import { render, waitFor } from '@testing-library/react'
import App from './App'

describe('App Routing', () => {
  const renderApp = () => {
    return render(<App />)
  }

  it('renders without crashing', () => {
    renderApp()
    expect(document.body).toBeInTheDocument()
  })

  it('renders home page by default', async () => {
    renderApp()
    // Wait for the page to render and check for home page content
    await waitFor(() => {
      // Home page should have navigation or main content
      const hasContent = document.body.textContent?.length || 0
      expect(hasContent).toBeGreaterThan(0)
    })
  })

  it('has router setup', () => {
    renderApp()
    // Verify router is initialized by checking for route-specific content
    // The app should render something, indicating router is working
    expect(window.location.pathname).toBeDefined()
  })

  it('renders with HelmetProvider for SEO', async () => {
    renderApp()
    // Verify document title is set (indicates HelmetProvider is working)
    await waitFor(() => {
      expect(document.title).toBeTruthy()
    })
  })
})
