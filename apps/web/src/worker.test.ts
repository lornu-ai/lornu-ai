import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { handleContactAPI } from '../worker'

// Mock Env for testing
const createMockEnv = () => ({
	ASSETS: { fetch: vi.fn() },
	RESEND_API_KEY: 'test-api-key',
	CONTACT_EMAIL: 'test@example.com',
	RATE_LIMIT_KV: {
		get: vi.fn(),
		put: vi.fn(),
		delete: vi.fn(),
	},
})

describe('Contact Form API', () => {
	// Mock fetch globally for all tests
	let mockFetch: ReturnType<typeof vi.fn>

	beforeEach(() => {
		mockFetch = vi.fn().mockResolvedValue(
			new Response(JSON.stringify({ id: 'email-123' }), {
				status: 200,
				headers: { 'Content-Type': 'application/json' },
			})
		)
		// Replace global fetch with mock
		globalThis.fetch = mockFetch as any
	})

	afterEach(() => {
		vi.restoreAllMocks()
		// Restore original fetch if it exists
		if (globalThis.fetch) {
			delete (globalThis as any).fetch
		}
	})

	describe('CORS Support', () => {
		it('handles OPTIONS preflight requests', async () => {
			const env = createMockEnv()
			const request = new Request('http://localhost/api/contact', {
				method: 'OPTIONS',
			})

			const response = await handleContactAPI(request, env)

			expect(response.status).toBe(204)
			expect(response.headers.get('Access-Control-Allow-Origin')).toBe('*')
			expect(response.headers.get('Access-Control-Allow-Methods')).toContain('POST')
			expect(response.headers.get('Access-Control-Allow-Headers')).toContain('Content-Type')
		})

		it('includes CORS headers on successful POST', async () => {
			const env = createMockEnv()
			// Mock KV to allow request (bypass rate limiting)
			env.RATE_LIMIT_KV.get = vi.fn().mockResolvedValue(null)

			const request = new Request('http://localhost/api/contact', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({
					name: 'Test User',
					email: 'test@example.com',
					message: 'Test message content here',
				}),
			})

			const response = await handleContactAPI(request, env)

			expect(response.headers.get('Access-Control-Allow-Origin')).toBe('*')
			expect(response.headers.get('Content-Type')).toContain('application/json')
		})

		it('includes CORS headers on error responses', async () => {
			const env = createMockEnv()
			const request = new Request('http://localhost/api/contact', {
				method: 'POST',
				headers: { 'Content-Length': '20000' },
				body: 'x'.repeat(20000),
			})

			const response = await handleContactAPI(request, env)

			expect(response.status).toBe(413)
			expect(response.headers.get('Access-Control-Allow-Origin')).toBe('*')
		})
	})

	describe('Request Size Validation', () => {
		it('rejects requests larger than 10KB', async () => {
			const env = createMockEnv()
			const request = new Request('http://localhost/api/contact', {
				method: 'POST',
				headers: { 'Content-Length': '11000' },
				body: JSON.stringify({
					name: 'Test',
					email: 'test@example.com',
					message: 'x'.repeat(10500),
				}),
			})

			const response = await handleContactAPI(request, env)

			expect(response.status).toBe(413)
			const data = await response.json()
			expect(data.error).toContain('too large')
		})

		it('accepts requests at exactly 10KB', async () => {
			const env = createMockEnv()
			const request = new Request('http://localhost/api/contact', {
				method: 'POST',
				headers: { 'Content-Length': '10240' },
				body: JSON.stringify({
					name: 'Test User',
					email: 'test@example.com',
					message: 'x'.repeat(10000),
				}),
			})

			// This should NOT return 413
			const response = await handleContactAPI(request, env)
			expect(response.status).not.toBe(413)
		})

		it('allows requests without Content-Length header', async () => {
			const env = createMockEnv()
			const request = new Request('http://localhost/api/contact', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({
					name: 'Test User',
					email: 'test@example.com',
					message: 'Valid message',
				}),
			})

			const response = await handleContactAPI(request, env)

			// Should not return 413, should continue with validation
			expect(response.status).not.toBe(413)
		})
	})

	describe('Email Validation', () => {
		it('rejects invalid email addresses (multiple @)', async () => {
			const env = createMockEnv()
			const request = new Request('http://localhost/api/contact', {
				method: 'POST',
				body: JSON.stringify({
					name: 'Test User',
					email: 'invalid@@example.com',
					message: 'Test message',
				}),
			})

			const response = await handleContactAPI(request, env)

			expect(response.status).toBe(400)
			const data = await response.json()
			expect(data.error).toContain('email')
		})

		it('rejects invalid email addresses (consecutive dots)', async () => {
			const env = createMockEnv()
			const request = new Request('http://localhost/api/contact', {
				method: 'POST',
				body: JSON.stringify({
					name: 'Test User',
					email: 'user@domain..com',
					message: 'Test message',
				}),
			})

			const response = await handleContactAPI(request, env)

			expect(response.status).toBe(400)
			const data = await response.json()
			expect(data.error).toContain('email')
		})

		it('rejects email addresses over 254 characters', async () => {
			const env = createMockEnv()
			const longEmail = 'a'.repeat(250) + '@example.com'

			const request = new Request('http://localhost/api/contact', {
				method: 'POST',
				body: JSON.stringify({
					name: 'Test User',
					email: longEmail,
					message: 'Test message',
				}),
			})

			const response = await handleContactAPI(request, env)

			expect(response.status).toBe(400)
			const data = await response.json()
			expect(data.error).toContain('email')
		})

		it('accepts valid email addresses', async () => {
			const env = createMockEnv()
			// Mock KV to allow request (bypass rate limiting)
			env.RATE_LIMIT_KV.get = vi.fn().mockResolvedValue(null)

			const validEmails = [
				'test@example.com',
				'user.name@example.com',
				'user+tag@example.co.uk',
				'test123@sub.example.org',
			]

			for (const email of validEmails) {
				const request = new Request('http://localhost/api/contact', {
					method: 'POST',
					body: JSON.stringify({
						name: 'Test User',
						email,
						message: 'Test message',
					}),
				})

				const response = await handleContactAPI(request, env)

				// Should not be 400 (validation error)
				// May be 429 (rate limit), 500 (email send), but not validation
				expect(response.status).not.toBe(400)
			}
		})
	})

	describe('Input Field Validation', () => {
		it('rejects missing name field', async () => {
			const env = createMockEnv()
			const request = new Request('http://localhost/api/contact', {
				method: 'POST',
				body: JSON.stringify({
					email: 'test@example.com',
					message: 'Test message',
				}),
			})

			const response = await handleContactAPI(request, env)

			expect(response.status).toBe(400)
			const data = await response.json()
			expect(data.error).toContain('Name')
		})

		it('rejects name shorter than 2 characters', async () => {
			const env = createMockEnv()
			const request = new Request('http://localhost/api/contact', {
				method: 'POST',
				body: JSON.stringify({
					name: 'A',
					email: 'test@example.com',
					message: 'Test message',
				}),
			})

			const response = await handleContactAPI(request, env)

			expect(response.status).toBe(400)
			const data = await response.json()
			expect(data.error).toContain('Name')
		})

		it('rejects message shorter than 10 characters', async () => {
			const env = createMockEnv()
			const request = new Request('http://localhost/api/contact', {
				method: 'POST',
				body: JSON.stringify({
					name: 'Test User',
					email: 'test@example.com',
					message: 'short',
				}),
			})

			const response = await handleContactAPI(request, env)

			expect(response.status).toBe(400)
			const data = await response.json()
			expect(data.error).toContain('Message')
		})

		it('rejects invalid JSON body', async () => {
			const env = createMockEnv()
			const request = new Request('http://localhost/api/contact', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: '{invalid json}',
			})

			const response = await handleContactAPI(request, env)

			expect(response.status).toBe(400)
			const data = await response.json()
			expect(data.error).toContain('JSON')
		})
	})

	describe('XSS Prevention', () => {
		it('sanitizes dangerous characters in name', async () => {
			const env = createMockEnv()
			// Mock KV to allow request (bypass rate limiting)
			env.RATE_LIMIT_KV.get = vi.fn().mockResolvedValue(null)

			// Track what was sent to fetch
			let sentBody: string | null = null
			mockFetch.mockImplementation((url: string, options: RequestInit) => {
				sentBody = options.body as string
				return Promise.resolve(
					new Response(JSON.stringify({ id: 'email-123' }), {
						status: 200,
						headers: { 'Content-Type': 'application/json' },
					})
				)
			})

			const request = new Request('http://localhost/api/contact', {
				method: 'POST',
				body: JSON.stringify({
					name: '<script>alert("xss")</script>',
					email: 'test@example.com',
					message: 'Test message content here',
				}),
			})

			const response = await handleContactAPI(request, env)

			// Should not reject - should sanitize and send
			expect(response.status).not.toBe(400)

			// Verify that dangerous characters are sanitized and HTML-encoded in the email body
			if (sentBody) {
				const emailData = JSON.parse(sentBody)
				// The name is sanitized (<> removed by sanitizeString) then HTML-encoded
				// So we should see the sanitized version (script tags removed) in the HTML
				expect(emailData.html).toContain('script')
				// But the < and > should be removed by sanitizeString, not encoded
				expect(emailData.html).not.toContain('<script>')
			}
		})

		it('sanitizes dangerous characters in message', async () => {
			const env = createMockEnv()
			// Mock KV to allow request (bypass rate limiting)
			env.RATE_LIMIT_KV.get = vi.fn().mockResolvedValue(null)

			// Track what was sent to fetch
			let sentBody: string | null = null
			mockFetch.mockImplementation((url: string, options: RequestInit) => {
				sentBody = options.body as string
				return Promise.resolve(
					new Response(JSON.stringify({ id: 'email-123' }), {
						status: 200,
						headers: { 'Content-Type': 'application/json' },
					})
				)
			})

			const request = new Request('http://localhost/api/contact', {
				method: 'POST',
				body: JSON.stringify({
					name: 'Test User',
					email: 'test@example.com',
					message: '<img src=x onerror="alert(1)">',
				}),
			})

			const response = await handleContactAPI(request, env)

			// Should not reject - should sanitize and send
			expect(response.status).not.toBe(400)

			// Verify that dangerous characters are sanitized and HTML-encoded in the email body
			if (sentBody) {
				const emailData = JSON.parse(sentBody)
				// The message is sanitized (<> removed by sanitizeString) then HTML-encoded
				// So we should see the sanitized version (img tag removed) in the HTML
				expect(emailData.html).toContain('img src=x')
				// But the < and > should be removed by sanitizeString, not encoded
				expect(emailData.html).not.toContain('<img')
			}
		})
	})

	describe('HTTP Method Validation', () => {
		it('rejects GET requests', async () => {
			const env = createMockEnv()
			const request = new Request('http://localhost/api/contact', {
				method: 'GET',
			})

			const response = await handleContactAPI(request, env)

			expect(response.status).toBe(405)
			const data = await response.json()
			expect(data.error).toContain('not allowed')
		})

		it('rejects PUT requests', async () => {
			const env = createMockEnv()
			const request = new Request('http://localhost/api/contact', {
				method: 'PUT',
			})

			const response = await handleContactAPI(request, env)

			expect(response.status).toBe(405)
		})

		it('allows POST requests', async () => {
			const env = createMockEnv()
			// Mock KV to allow request (bypass rate limiting)
			env.RATE_LIMIT_KV.get = vi.fn().mockResolvedValue(null)

			const request = new Request('http://localhost/api/contact', {
				method: 'POST',
				body: JSON.stringify({
					name: 'Test User',
					email: 'test@example.com',
					message: 'Test message content here',
				}),
			})

			const response = await handleContactAPI(request, env)

			// Should not be 405
			expect(response.status).not.toBe(405)
		})
	})

	describe('Response Format', () => {
		it('returns JSON with proper error structure', async () => {
			const env = createMockEnv()
			const request = new Request('http://localhost/api/contact', {
				method: 'POST',
				body: JSON.stringify({
					name: 'A',
					email: 'test@example.com',
					message: 'Test',
				}),
			})

			const response = await handleContactAPI(request, env)
			const data = await response.json()

			expect(data).toHaveProperty('error')
			expect(typeof data.error).toBe('string')
		})

		it('returns appropriate status codes', async () => {
			const env = createMockEnv()

			const testCases = [
				{
					method: 'OPTIONS',
					expectedStatus: 204,
					name: 'OPTIONS preflight',
				},
				{
					method: 'GET',
					expectedStatus: 405,
					name: 'GET method not allowed',
				},
			]

			for (const testCase of testCases) {
				const request = new Request('http://localhost/api/contact', {
					method: testCase.method,
				})

				const response = await handleContactAPI(request, env)
				expect(response.status).toBe(testCase.expectedStatus)
			}
		})
	})
})
