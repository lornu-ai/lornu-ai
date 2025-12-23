import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { BrowserRouter } from 'react-router-dom'
import { HelmetProvider } from 'react-helmet-async'
import Home from './Home'


// Mock toast notifications
const mockToastSuccess = vi.fn()
const mockToastError = vi.fn()

vi.mock('sonner', () => ({
  toast: {
    success: (...args: unknown[]) => mockToastSuccess(...args),
    error: (...args: unknown[]) => mockToastError(...args),
  },
}))

describe('Home Page - Contact Form Integration', () => {
  const originalFetch = global.fetch
  let mockFetch: ReturnType<typeof vi.fn>

  beforeEach(() => {
    mockFetch = vi.fn()
    global.fetch = mockFetch
    vi.clearAllMocks()
  })

  afterEach(() => {
    global.fetch = originalFetch
  })

  const renderHome = () => {
    return render(
      <HelmetProvider>
        <BrowserRouter>
          <Home />
        </BrowserRouter>
      </HelmetProvider>
    )
  }

  it('submits contact form successfully with mocked API', async () => {
    const user = userEvent.setup()

    // Mock successful API response
    mockFetch.mockResolvedValueOnce({
      ok: true,
      text: async () => JSON.stringify({ success: true, message: 'Message sent successfully' }),
    } as unknown as Response)

    renderHome()

    // Fill in form fields
    const nameInput = screen.getByLabelText(/name/i)
    const emailInput = screen.getByLabelText(/email/i)
    const messageInput = screen.getByLabelText(/message/i)
    const submitButton = screen.getByRole('button', { name: /send message/i })

    await user.type(nameInput, 'Jane Doe')
    await user.type(emailInput, 'jane@example.com')
    await user.type(messageInput, 'Looking forward to working with you!')

    // Submit form
    await user.click(submitButton)

    // Verify API was called
    await waitFor(() => {
      expect(mockFetch).toHaveBeenCalledWith('/api/contact', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name: 'Jane Doe',
          email: 'jane@example.com',
          message: 'Looking forward to working with you!',
        }),
      })
    })

    // Verify success toast was called
    await waitFor(() => {
      expect(mockToastSuccess).toHaveBeenCalledWith("Message sent! We'll be in touch soon.")
    })
  })

  it('shows error message when API call fails', async () => {
    const user = userEvent.setup()

    // Mock failed API response
    mockFetch.mockResolvedValueOnce({
      ok: false,
      text: async () => JSON.stringify({ error: 'Failed to send message' }),
    } as unknown as Response)

    renderHome()

    // Fill in form fields
    const nameInput = screen.getByLabelText(/name/i)
    const emailInput = screen.getByLabelText(/email/i)
    const messageInput = screen.getByLabelText(/message/i)
    const submitButton = screen.getByRole('button', { name: /send message/i })

    await user.type(nameInput, 'Jane Doe')
    await user.type(emailInput, 'jane@example.com')
    await user.type(messageInput, 'Test message')

    // Submit form
    await user.click(submitButton)

    // Verify error toast was called
    await waitFor(() => {
      expect(mockToastError).toHaveBeenCalled()
    })
  })
})
