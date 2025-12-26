# Contact Form Setup Guide

This guide explains how to configure the contact form API endpoint to send emails to `contact@lornu.ai`.

## Overview

The contact form on the home page submits to the `/api/contact` endpoint, which:
- Validates the form data
- Applies rate limiting (optional, depending on backend implementation)
- Sends emails via the Resend API

The frontend only posts to `/api/contact`; the backend service in Kubernetes is responsible for handling the request.

## Required Configuration

### 1. Resend Account Setup & Domain Verification

**Important:** Before sending emails, you must verify your domain in Resend.

1. Sign up at [resend.com](https://resend.com) (free tier: 1,000 emails/month)
2. Verify your domain (`lornu.ai`) in Resend:
   - Go to **Domains** in the Resend dashboard
   - Click **Add Domain** and enter `lornu.ai`
   - Add the required DNS records (SPF, DKIM, DMARC, and Return-Path if used)
   - Wait for verification
3. Create an API key:
   - Go to **API Keys** in the Resend dashboard
   - Click **Create API Key**
   - Give your API key a name (e.g., "k8s-production")
   - Select **Sending access** permission
   - Copy the API key immediately (you won't be able to see it again)

### 2. Configure Secrets in Kubernetes

The backend deployment reads secrets from a Kubernetes Secret named `lornu-ai-secrets`.

Create or update the secret with the Resend API key:

```bash
kubectl -n <namespace> create secret generic lornu-ai-secrets \
  --from-literal=RESEND_API_KEY=YOUR_RESEND_API_KEY \
  --dry-run=client -o yaml | kubectl apply -f -
```

Optional secret to override the default recipient (defaults to `contact@lornu.ai`):

```bash
kubectl -n <namespace> create secret generic lornu-ai-secrets \
  --from-literal=CONTACT_EMAIL=team@lornu.ai \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Local Testing

You can exercise the API endpoint once the backend is running locally or in a dev namespace:

```bash
curl -X POST http://localhost:8080/api/contact \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "message": "This is a test message"
  }'
```

If you use the frontend dev server, the backend must be reachable at the same origin or via a configured proxy.

## Email Format

Emails sent from the contact form include:
- **From:** LornuAI Contact Form <noreply@lornu.ai>
- **To:** contact@lornu.ai (or value of `CONTACT_EMAIL`)
- **Reply-To:** Submitter's email address
- **Subject:** "New Contact Form Submission from [Name]"
- **Body:** Includes name, email, and message (HTML and plain text)

## Troubleshooting

### Emails not sending

1. **Verify domain is verified in Resend**
2. **Check `RESEND_API_KEY` is set in the Kubernetes secret**
3. **Verify Resend API key permissions**
4. **Test the Resend API directly**

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
