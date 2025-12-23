import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { BrowserRouter } from 'react-router-dom'
import { HelmetProvider } from 'react-helmet-async'
import Home from './Home'

// Mock the toast library
const mockToastSuccess = vi.fn()
const mockToastError = vi.fn()

vi.mock('sonner', () => ({
  toast: {
    success: (...args: unknown[]) => mockToastSuccess(...args),
    error: (...args: unknown[]) => mockToastError(...args),
  },
}))

const renderHome = () => {
  return render(
    <HelmetProvider>
      <BrowserRouter>
        <Home />
      </BrowserRouter>
    </HelmetProvider>
  )
}

describe('Home - Contact Form Submission', () => {
  let fetchMock: ReturnType<typeof vi.fn>

  beforeEach(() => {
    fetchMock = vi.fn()
    global.fetch = fetchMock
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('should successfully submit form with JSON response', async () => {
    const user = userEvent.setup()
    fetchMock.mockResolvedValueOnce({
      ok: true,
      text: async () => JSON.stringify({ success: true, message: 'Message sent' }),
    })

    renderHome()

    const nameInput = screen.getByLabelText(/name/i)
    const emailInput = screen.getByLabelText(/email/i)
    const messageInput = screen.getByLabelText(/message/i)
    const submitButton = screen.getByRole('button', { name: /send message/i })

    await user.type(nameInput, 'John Doe')
    await user.type(emailInput, 'john@example.com')
    await user.type(messageInput, 'This is a test message')
    await user.click(submitButton)

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledWith(
        '/api/contact',
        expect.objectContaining({
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            name: 'John Doe',
            email: 'john@example.com',
            message: 'This is a test message',
          }),
        })
      )
    })
  })

  it('should handle non-JSON error responses (e.g., 502 Bad Gateway)', async () => {
    const user = userEvent.setup()
    const errorText = '502 Bad Gateway from Cloudflare'

    fetchMock.mockResolvedValueOnce({
      ok: false,
      status: 502,
      text: async () => errorText,
    })

    renderHome()

    const nameInput = screen.getByLabelText(/name/i)
    const emailInput = screen.getByLabelText(/email/i)
    const messageInput = screen.getByLabelText(/message/i)
    const submitButton = screen.getByRole('button', { name: /send message/i })

    await user.type(nameInput, 'John Doe')
    await user.type(emailInput, 'john@example.com')
    await user.type(messageInput, 'This is a test message')
    await user.click(submitButton)

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalled()
    })
  })

  it('should handle JSON error responses', async () => {
    const user = userEvent.setup()
    fetchMock.mockResolvedValueOnce({
      ok: false,
      status: 400,
      text: async () => JSON.stringify({ error: 'Invalid email address' }),
    })

    renderHome()

    const nameInput = screen.getByLabelText(/name/i)
    const emailInput = screen.getByLabelText(/email/i)
    const messageInput = screen.getByLabelText(/message/i)
    const submitButton = screen.getByRole('button', { name: /send message/i })

    await user.type(nameInput, 'John Doe')
    await user.type(emailInput, 'test@example.com')
    await user.type(messageInput, 'This is a test message')
    await user.click(submitButton)

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalled()
      expect(mockToastError).toHaveBeenCalledWith('Invalid email address')
    }, { timeout: 3000 })
  })

  it('should handle network failures', async () => {
    const user = userEvent.setup()
    fetchMock.mockRejectedValueOnce(new Error('Network error'))

    renderHome()

    const nameInput = screen.getByLabelText(/name/i)
    const emailInput = screen.getByLabelText(/email/i)
    const messageInput = screen.getByLabelText(/message/i)
    const submitButton = screen.getByRole('button', { name: /send message/i })

    await user.type(nameInput, 'John Doe')
    await user.type(emailInput, 'john@example.com')
    await user.type(messageInput, 'This is a test message')
    await user.click(submitButton)

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalled()
    })
  })

  it('should show validation error when required fields are missing', async () => {
    const user = userEvent.setup()
    renderHome()

    const submitButton = screen.getByRole('button', { name: /send message/i })
    await user.click(submitButton)

    // Fetch should not be called due to validation
    expect(fetchMock).not.toHaveBeenCalled()
  })
})
