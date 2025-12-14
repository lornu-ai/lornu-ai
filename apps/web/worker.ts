
export interface Env {
	ASSETS: Fetcher;
	RESEND_API_KEY: string;
	// Optional: Override default contact email (defaults to contact@lornu.ai)
	CONTACT_EMAIL?: string;
	// Optional: KV namespace for rate limiting
	RATE_LIMIT_KV?: KVNamespace;
}

/**
 * MIME type mappings for common file extensions
 * Used as fallback when ASSETS binding doesn't provide Content-Type
 */
const MIME_TYPES: Record<string, string> = {
	// Text files
	'.html': 'text/html;charset=UTF-8',
	'.css': 'text/css;charset=UTF-8',
	'.js': 'application/javascript;charset=UTF-8',
	'.mjs': 'application/javascript;charset=UTF-8',
	'.json': 'application/json;charset=UTF-8',
	'.xml': 'application/xml;charset=UTF-8',
	'.txt': 'text/plain;charset=UTF-8',

	// Images
	'.svg': 'image/svg+xml',
	'.png': 'image/png',
	'.jpg': 'image/jpeg',
	'.jpeg': 'image/jpeg',
	'.gif': 'image/gif',
	'.webp': 'image/webp',
	'.ico': 'image/x-icon',
	'.bmp': 'image/bmp',

	// Fonts
	'.woff': 'font/woff',
	'.woff2': 'font/woff2',
	'.ttf': 'font/ttf',
	'.otf': 'font/otf',
	'.eot': 'application/vnd.ms-fontobject',

	// Media
	'.mp4': 'video/mp4',
	'.webm': 'video/webm',
	'.mp3': 'audio/mpeg',
	'.wav': 'audio/wav',
	'.ogg': 'audio/ogg',

	// Documents
	'.pdf': 'application/pdf',
	'.zip': 'application/zip',
	'.tar': 'application/x-tar',
	'.gz': 'application/gzip',
};

/**
 * Determines the MIME type for a given file path
 * @param path - The URL pathname
 * @returns MIME type string or null if not found
 */
function getMimeType(path: string): string | null {
	const lowerPath = path.toLowerCase();
	const ext = lowerPath.substring(lowerPath.lastIndexOf('.'));
	return MIME_TYPES[ext] || null;
}

/**
 * Rate limiting configuration
 */
const RATE_LIMIT_WINDOW = 60 * 60 * 1000; // 1 hour in milliseconds
const RATE_LIMIT_MAX_REQUESTS = 5; // Max 5 requests per hour per IP

/**
 * Validates email format using a more robust RFC 5322-compliant pattern
 * This regex pattern is more strict than the basic pattern and prevents:
 * - Multiple consecutive @ symbols (e.g., "user@@domain.com")
 * - Multiple consecutive dots in domain (e.g., "user@domain..com")
 * - Missing TLD (e.g., "user@domain")
 * - Invalid characters in local or domain parts
 *
 * Pattern breakdown:
 * - ^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+  Local part: alphanumeric + common special chars
 * - @  Single @ symbol required
 * - [a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?  Domain: valid domain name
 * - (?:\.  Start of TLD part
 * - [a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+  One or more TLD segments
 * - $  End of string
 */
function isValidEmail(email: string): boolean {
	// More robust RFC 5322-compliant email regex
	// This pattern is stricter and prevents common invalid formats
	const emailRegex = /^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/;

	// Additional checks for edge cases
	if (!email || email.length > 254) { // RFC 5321 max email length
		return false;
	}

	// Check for consecutive dots (invalid)
	if (email.includes('..')) {
		return false;
	}

	// Check that @ appears exactly once
	const atCount = (email.match(/@/g) || []).length;
	if (atCount !== 1) {
		return false;
	}

	// Check that local part (before @) is not empty
	const localPart = email.split('@')[0];
	if (!localPart || localPart.length === 0 || localPart.length > 64) { // RFC 5321 max local part length
		return false;
	}

	return emailRegex.test(email);
}

/**
 * HTML-encodes a string to prevent XSS attacks when inserting into HTML context
 * Encodes special characters that could be used for XSS: <, >, &, ", ', /
 */
function htmlEncode(input: string): string {
	return input
		.replace(/&/g, '&amp;')
		.replace(/</g, '&lt;')
		.replace(/>/g, '&gt;')
		.replace(/"/g, '&quot;')
		.replace(/'/g, '&#39;')
		.replace(/\//g, '&#x2F;');
}

/**
 * Sanitizes string input to prevent XSS attacks
 * Trims whitespace, limits length, and removes potentially dangerous characters
 * For HTML context, use htmlEncode() instead
 *
 * @param input - The string to sanitize
 * @param maxLength - Maximum allowed length in characters
 *                    Suggested values:
 *                    - Name: 200 chars (typical name length + buffer)
 *                    - Email: 254 chars (RFC 5321 maximum)
 *                    - Message: 5000 chars (reasonable for email body)
 */
function sanitizeString(input: string, maxLength: number = 5000): string {
	return input
		.trim()
		.replace(/[\r\n]/g, ' ') // Remove newlines and replace with space
		.slice(0, maxLength)
		.replace(/[<>]/g, '');
}

/**
 * Validates and sanitizes contact form data
 */
function validateContactForm(data: unknown): { valid: boolean; data?: { name: string; email: string; message: string }; error?: string } {
	if (!data || typeof data !== 'object') {
		return { valid: false, error: 'Invalid request body' };
	}

	const { name, email, message } = data as Record<string, unknown>;

	if (!name || typeof name !== 'string' || name.trim().length < 2) {
		return { valid: false, error: 'Name must be at least 2 characters' };
	}

	if (!email || typeof email !== 'string' || !isValidEmail(email)) {
		return { valid: false, error: 'Invalid email address' };
	}

	if (!message || typeof message !== 'string' || message.trim().length < 10) {
		return { valid: false, error: 'Message must be at least 10 characters' };
	}

	return {
		valid: true,
		data: {
			name: sanitizeString(name, 200),
			email: email.trim().toLowerCase(),
			message: sanitizeString(message, 5000),
		},
	};
}

/**
 * Checks rate limit for an IP address
 */
async function checkRateLimit(ip: string, kv: KVNamespace | undefined): Promise<{ allowed: boolean; remaining: number }> {
	if (!kv) {
		// If KV is not configured, allow all requests (rate limiting disabled)
		return { allowed: true, remaining: RATE_LIMIT_MAX_REQUESTS };
	}

	const key = `rate_limit:${ip}`;
	const now = Date.now();

	try {
		const stored = await kv.get(key);
		if (!stored) {
			// First request from this IP
			await kv.put(key, JSON.stringify({ count: 1, resetAt: now + RATE_LIMIT_WINDOW }), {
				expirationTtl: Math.floor(RATE_LIMIT_WINDOW / 1000),
			});
			return { allowed: true, remaining: RATE_LIMIT_MAX_REQUESTS - 1 };
		}

		const { count, resetAt } = JSON.parse(stored);
		if (now > resetAt) {
			// Window expired, reset
			await kv.put(key, JSON.stringify({ count: 1, resetAt: now + RATE_LIMIT_WINDOW }), {
				expirationTtl: Math.floor(RATE_LIMIT_WINDOW / 1000),
			});
			return { allowed: true, remaining: RATE_LIMIT_MAX_REQUESTS - 1 };
		}

		if (count >= RATE_LIMIT_MAX_REQUESTS) {
			return { allowed: false, remaining: 0 };
		}

		// Increment count
		await kv.put(key, JSON.stringify({ count: count + 1, resetAt }), {
			expirationTtl: Math.floor((resetAt - now) / 1000),
		});
		return { allowed: true, remaining: RATE_LIMIT_MAX_REQUESTS - count - 1 };
	} catch (error) {
		console.error('Rate limit check failed:', error);
		// On error, allow the request (fail open)
		return { allowed: true, remaining: RATE_LIMIT_MAX_REQUESTS };
	}
}

/**
 * Gets client IP address from request
 */
function getClientIP(request: Request): string {
	// Try CF-Connecting-IP header first (Cloudflare)
	const cfIP = request.headers.get('CF-Connecting-IP');
	if (cfIP) return cfIP;

	// Fallback to X-Forwarded-For
	const xForwardedFor = request.headers.get('X-Forwarded-For');
	if (xForwardedFor) {
		return xForwardedFor.split(',')[0].trim();
	}

	// Fallback to a default value (shouldn't happen with Cloudflare)
	return 'unknown';
}

/**
 * Sends email using Resend API
 */
async function sendEmail(
	data: { name: string; email: string; message: string },
	env: Env
): Promise<{ success: boolean; error?: string }> {
	const toEmail = env.CONTACT_EMAIL || 'contact@lornu.ai';

	try {
		const response = await fetch('https://api.resend.com/emails', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				'Authorization': `Bearer ${env.RESEND_API_KEY}`,
			},
			body: JSON.stringify({
				from: 'LornuAI Contact Form <noreply@lornu.ai>',
				to: [toEmail],
				replyTo: data.email,
				// data.name is already sanitized in validateContactForm with 200 chars
				// No need to sanitize again, just ensure it's safe for email subject
				subject: `New Contact Form Submission from ${data.name.slice(0, 100)}`,
				html: `
					<h2>New Contact Form Submission</h2>
					<p><strong>Name:</strong> ${htmlEncode(data.name)}</p>
					<p><strong>Email:</strong> ${htmlEncode(data.email)}</p>
					<p><strong>Message:</strong></p>
					<p>${htmlEncode(data.message).replace(/\n/g, '<br>')}</p>
				`,
				text: `
New Contact Form Submission

Name: ${data.name}
Email: ${data.email}

Message:
${data.message}
				`.trim(),
			}),
		});

		if (!response.ok) {
			const errorData = await response.json().catch(() => ({}));
			console.error('Resend API error:', {
				status: response.status,
				statusText: response.statusText,
				error: errorData,
			});

			// Provide more specific error messages based on status codes
			if (response.status === 401) {
				return {
					success: false,
					error: 'Authentication failed. Please check RESEND_API_KEY secret.',
				};
			}
			if (response.status === 403) {
				return {
					success: false,
					error: 'API key lacks permission to send emails. Check API key permissions in Resend dashboard.',
				};
			}
			if (response.status === 422) {
				return {
					success: false,
					error: errorData.message || 'Invalid email configuration. Check domain verification.',
				};
			}

			return {
				success: false,
				error: errorData.message || 'Failed to send email. Please try again later.',
			};
		}

		const result = await response.json().catch(() => ({}));
		console.log('Email sent successfully:', result);
		return { success: true };
	} catch (error) {
		console.error('Email sending error:', error);
		return {
			success: false,
			error: 'Failed to send email. Please try again later.',
		};
	}
}

/**
 * Handles POST /api/contact requests
 */
async function handleContactAPI(request: Request, env: Env): Promise<Response> {
	// Only allow POST requests
	if (request.method !== 'POST') {
		return new Response(JSON.stringify({ error: 'Method not allowed' }), {
			status: 405,
			headers: { 'Content-Type': 'application/json' },
		});
	}

	// Check rate limit
	const clientIP = getClientIP(request);
	const rateLimit = await checkRateLimit(clientIP, env.RATE_LIMIT_KV);

	if (!rateLimit.allowed) {
		return new Response(
			JSON.stringify({
				error: 'Too many requests. Please try again later.',
			}),
			{
				status: 429,
				headers: {
					'Content-Type': 'application/json',
					'Retry-After': '3600', // 1 hour
				},
			}
		);
	}

	// Parse and validate request body
	let body: unknown;
	try {
		body = await request.json();
	} catch (error) {
		return new Response(JSON.stringify({ error: 'Invalid JSON in request body' }), {
			status: 400,
			headers: { 'Content-Type': 'application/json' },
		});
	}

	const validation = validateContactForm(body);
	if (!validation.valid || !validation.data) {
		return new Response(JSON.stringify({ error: validation.error || 'Validation failed' }), {
			status: 400,
			headers: { 'Content-Type': 'application/json' },
		});
	}

	// Send email
	const emailResult = await sendEmail(validation.data, env);
	if (!emailResult.success) {
		return new Response(JSON.stringify({ error: emailResult.error || 'Failed to send email' }), {
			status: 500,
			headers: { 'Content-Type': 'application/json' },
		});
	}

	// Success response
	return new Response(
		JSON.stringify({
			success: true,
			message: 'Message sent successfully',
		}),
		{
			status: 200,
			headers: {
				'Content-Type': 'application/json',
				'X-RateLimit-Remaining': rateLimit.remaining.toString(),
			},
		}
	);
}

export default {
	async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
		const url = new URL(request.url);

		// Handle API routes
		if (url.pathname === '/api/contact') {
			return handleContactAPI(request, env);
		}

		// Serve static assets
		const response = await env.ASSETS.fetch(request);

		// Check if Content-Type header is missing
		const contentType = response.headers.get("Content-Type");
		if (!contentType) {
			const mimeType = getMimeType(url.pathname);

			// If we found a matching MIME type, set it
			if (mimeType) {
				const newHeaders = new Headers(response.headers);
				newHeaders.set("Content-Type", mimeType);

				return new Response(response.body, {
					status: response.status,
					statusText: response.statusText,
					headers: newHeaders,
				});
			}
		}

		// Return original response if Content-Type exists or no MIME type match found
		return response;
	},
};
