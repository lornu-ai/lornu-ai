# Contact Form Setup Guide

This guide explains how to configure the contact form API endpoint to send emails to `contact@lornu.ai`.

## Overview

The contact form on the home page sends submissions to `/api/contact` endpoint, which:
- Validates the form data (client and server-side)
- Applies rate limiting (5 requests per hour per IP, optional with KV)
- Sends emails via Resend API to `contact@lornu.ai`

### Why Resend?

Resend is an excellent fit for Cloudflare Workers:
- **Simple REST API**: Uses native `fetch()` - no heavy SDKs needed
- **Perfect for Serverless**: Designed for edge/serverless environments
- **Generous Free Tier**: 1,000 emails/month free
- **TypeScript-Friendly**: Excellent DX with clear documentation
- **Secure**: API key stored as Cloudflare Worker secret
- **Reliable**: Built on highly reliable email infrastructure

## Required Configuration

### 1. Resend Account Setup & Domain Verification

**Important:** Before sending emails, you must verify your domain in Resend.

1. Sign up at [resend.com](https://resend.com) (free tier: 1,000 emails/month)
2. Verify your domain (`lornu.ai`) in Resend:
   - Go to **Domains** in the Resend dashboard
   - Click **Add Domain** and enter `lornu.ai`
   - **Return-Path (Optional):** By default, Resend uses `send.lornu.ai` for bounce handling. You can optionally set a custom Return-Path subdomain (e.g., `bounce.lornu.ai` or `outbound.lornu.ai`) during domain setup if you prefer or have existing DNS conflicts
   - Add the required DNS records (SPF, DKIM, DMARC, and Return-Path if custom) to your domain's DNS provider
   - Wait for verification (usually takes a few minutes)
3. Create an API key:
   - Go to **API Keys** in the Resend dashboard
   - Click **Create API Key**
   - Give your API key a name (e.g., "Cloudflare Worker - Production")
   - Select **Full access** or **Sending access** permission
     - **Sending access** is recommended for security (limits to email sending only)
     - If using **Sending access**, you can optionally restrict to `lornu.ai` domain
   - Copy the API key immediately (you won't be able to see it again)
4. Set it as a Cloudflare Worker secret:

```bash
cd apps/web
bunx wrangler secret put RESEND_API_KEY
# Paste your Resend API key when prompted
```

**Note:** The `from` address in the code is `noreply@lornu.ai`. This domain must be verified in Resend before emails will send. You can also use other verified addresses like `contact@lornu.ai` or `hello@lornu.ai`.

### 2. Contact Email (Optional - Not Required)

By default, emails are sent to `contact@lornu.ai` (hardcoded in the worker). **No secret needed** - this email is already configured in the code.

Only set `CONTACT_EMAIL` as a secret if you want to override the default:

```bash
bunx wrangler secret put CONTACT_EMAIL
# Enter the email address (e.g., sales@lornu.ai)
```

**Recommendation:** Don't set this secret unless you need a different recipient. The default `contact@lornu.ai` is already configured.

## Optional: Rate Limiting with KV

Rate limiting prevents abuse by limiting submissions to 5 per hour per IP address.

**To enable rate limiting:**

1. Create a KV namespace in Cloudflare Dashboard:
   - Go to **Workers & Pages** → **KV**
   - Click **Create a namespace**
   - Name it (e.g., `rate-limit`)

2. Update `wrangler.toml`:
   ```toml
   kv_namespaces = [
     { binding = "RATE_LIMIT_KV", id = "your-namespace-id" }
   ]
   ```

3. Deploy the updated configuration

**Note:** If KV is not configured, rate limiting is disabled (requests are allowed). This is safe but less secure.

## Testing Locally

For local development, you can test the API endpoint:

1. Start the dev server:
   ```bash
   bun run dev
   ```

2. Test the endpoint:
   ```bash
   curl -X POST http://localhost:5173/api/contact \
     -H "Content-Type: application/json" \
     -d '{
       "name": "Test User",
       "email": "test@example.com",
       "message": "This is a test message"
     }'
   ```

**Note:** Local testing requires secrets to be configured. Use `wrangler dev` for testing with Cloudflare Workers environment:

```bash
bunx wrangler dev
```

## Production Deployment

1. Ensure the required secret is set in Cloudflare:
   - `RESEND_API_KEY` (required - set via `bunx wrangler secret put RESEND_API_KEY`)
   - `CONTACT_EMAIL` (optional - only needed if overriding default `contact@lornu.ai`)
   - `RATE_LIMIT_KV` KV namespace (optional - only needed if enabling rate limiting)

2. Deploy via Cloudflare Git Integration (automatic on push to `main` or `develop`)

3. Verify the contact form at `https://lornu.ai` (scroll to contact section)

## Email Format

Emails sent from the contact form include:
- **From:** LornuAI Contact Form <noreply@lornu.ai> (must be from verified domain)
- **To:** contact@lornu.ai (or value of CONTACT_EMAIL secret)
- **Reply-To:** Submitter's email address (so you can reply directly)
- **Subject:** "New Contact Form Submission from [Name]"
- **Body:** Includes name, email, and message (HTML and plain text formats)

**Implementation Note:** The worker uses a simple `fetch()` call to Resend's REST API - no external SDK needed, keeping the bundle size small and execution fast on Cloudflare Workers.

## Troubleshooting

### Emails not sending

1. **Verify domain is verified in Resend:**
   - Check Resend Dashboard → Domains
   - Ensure `lornu.ai` shows as "Verified" (green checkmark)
   - If not verified, add the DNS records and wait for verification

2. **Check Resend API key is set correctly:**
   ```bash
   bunx wrangler secret list
   ```

3. **Verify Resend API key permissions:**
   - Check the API key has at least **Sending access** permission
   - If using domain-restricted key, ensure `lornu.ai` is included
   - API key must have been created (not expired or deleted)

4. **Check Cloudflare Worker logs for errors:**
   - Go to Cloudflare Dashboard → Workers & Pages → lornu-ai → Logs
   - Look for Resend API errors or validation failures

5. **Test the Resend API directly:**
   ```bash
   curl -X POST https://api.resend.com/emails \
     -H "Authorization: Bearer YOUR_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "from": "noreply@lornu.ai",
       "to": ["contact@lornu.ai"],
       "subject": "Test",
       "html": "<p>Test email</p>"
     }'
   ```

### Rate limiting not working

1. Ensure KV namespace is created and bound in `wrangler.toml`
2. Verify the binding name matches: `RATE_LIMIT_KV`
3. Check KV namespace ID is correct

### CORS errors

The API endpoint should not have CORS issues since it's on the same domain. If you see CORS errors, check:
- The request is being made to the correct domain
- The worker is properly deployed and accessible

## Security Considerations

- **Input validation:** All inputs are validated and sanitized on the server
- **Rate limiting:** Optional KV-based rate limiting prevents abuse
- **XSS protection:** User input is sanitized before being included in email
- **Email validation:** Email addresses are validated both client and server-side
- **HTTPS only:** In production, all requests are over HTTPS
