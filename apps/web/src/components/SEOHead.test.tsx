import { describe, it, expect } from 'vitest'
import { render, waitFor } from '@testing-library/react'
import { HelmetProvider } from 'react-helmet-async'
import SEOHead from './SEOHead'

describe('SEOHead Component', () => {
  const renderWithHelmet = (ui: React.ReactElement) => {
    return render(<HelmetProvider>{ui}</HelmetProvider>)
  }

  it('appends LornuAI branding to title', async () => {
    renderWithHelmet(
      <SEOHead
        title="Test Page"
        description="Test description"
      />
    )

    await waitFor(() => {
      expect(document.title).toBe('Test Page | LornuAI')
    })
  })

  it('appends delimiter even if LornuAI already in title', async () => {
    renderWithHelmet(
      <SEOHead
        title="Test Page - LornuAI"
        description="Test description"
      />
    )

    await waitFor(() => {
      expect(document.title).toBe('Test Page - LornuAI | LornuAI')
    })
  })

  it('sets meta description', async () => {
    renderWithHelmet(
      <SEOHead
        title="Test Page"
        description="This is a test description"
      />
    )

    await waitFor(() => {
      const metaDescription = document.querySelector('meta[name="description"]')
      expect(metaDescription).toHaveAttribute('content', 'This is a test description')
    })
  })

  it('sets canonical URL correctly', async () => {
    renderWithHelmet(
      <SEOHead
        title="Test Page"
        description="Test description"
        canonical="/test-page"
      />
    )

    await waitFor(() => {
      const canonicalLink = document.querySelector('link[rel="canonical"]')
      expect(canonicalLink).toHaveAttribute('href', 'https://lornu.ai/test-page')
    })
  })

  it('uses default canonical URL when not provided', async () => {
    renderWithHelmet(
      <SEOHead
        title="Test Page"
        description="Test description"
      />
    )

    await waitFor(() => {
      const canonicalLink = document.querySelector('link[rel="canonical"]')
      expect(canonicalLink).toHaveAttribute('href', 'https://lornu.ai')
    })
  })

  it('sets Open Graph tags', async () => {
    renderWithHelmet(
      <SEOHead
        title="Test Page"
        description="Test description"
        ogTitle="OG Test Title"
        ogDescription="OG Test Description"
        ogImage="https://example.com/image.png"
        ogType="article"
      />
    )

    await waitFor(() => {
      expect(document.querySelector('meta[property="og:title"]')).toHaveAttribute('content', 'OG Test Title')
      expect(document.querySelector('meta[property="og:description"]')).toHaveAttribute('content', 'OG Test Description')
      expect(document.querySelector('meta[property="og:image"]')).toHaveAttribute('content', 'https://example.com/image.png')
      expect(document.querySelector('meta[property="og:type"]')).toHaveAttribute('content', 'article')
    })
  })

  it('uses default og type as website', async () => {
    renderWithHelmet(
      <SEOHead
        title="Test Page"
        description="Test description"
      />
    )

    await waitFor(() => {
      expect(document.querySelector('meta[property="og:type"]')).toHaveAttribute('content', 'website')
    })
  })

  it('sets Twitter Card tags', async () => {
    renderWithHelmet(
      <SEOHead
        title="Test Page"
        description="Test description"
        twitterCard="summary"
      />
    )

    await waitFor(() => {
      expect(document.querySelector('meta[name="twitter:card"]')).toHaveAttribute('content', 'summary')
    })
  })

  it('uses default twitter card as summary_large_image', async () => {
    renderWithHelmet(
      <SEOHead
        title="Test Page"
        description="Test description"
      />
    )

    await waitFor(() => {
      expect(document.querySelector('meta[name="twitter:card"]')).toHaveAttribute('content', 'summary_large_image')
    })
  })

  it('sets robots meta tag to index, follow', async () => {
    renderWithHelmet(
      <SEOHead
        title="Test Page"
        description="Test description"
      />
    )

    await waitFor(() => {
      expect(document.querySelector('meta[name="robots"]')).toHaveAttribute('content', 'index, follow')
    })
  })
})
