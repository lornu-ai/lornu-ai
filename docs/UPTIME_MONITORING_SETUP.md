# Uptime Monitoring Setup Guide

**Status:** Ready for Implementation
**Last Updated:** 2025-12-15

## Overview

This guide walks through setting up external uptime monitoring and a public status page for `lornu.ai`.

## Prerequisites

- ✅ Health endpoint implemented: `https://lornu.ai/api/health`
- ✅ Status page link added to footer
- ✅ Cloudflare Performance Reporting configured (performance monitoring)
- ⏳ External monitoring service account needed
- ⏳ DNS access for `status.lornu.ai` subdomain

## Existing Monitoring

### Cloudflare Performance Reporting

You already have **Cloudflare Performance Reporting** configured:
- **URL:** [Performance Dashboard](https://dash.cloudflare.com/{your-account-id}/lornu.ai/speed/test/lornu.ai%2F/history/desktop/us-central1)
- **Monitors:** Desktop performance (US Central)
- **Metrics:** Core Web Vitals, page load times, performance scores

**Note:** This provides performance monitoring but not uptime/availability monitoring. The external monitoring service (UptimeRobot, etc.) will complement this by:
- Checking availability (is the site up?)
- Alerting on downtime
- Providing public status page
- Monitoring health endpoint specifically

## Monitoring Strategy

### Current Setup
- **Performance Monitoring:** Cloudflare Performance Reporting (already configured)
- **Uptime Monitoring:** External service needed (see below)

### Why Both?
- **Cloudflare Performance:** Tracks page speed, Core Web Vitals, user experience
- **External Uptime:** Tracks availability, alerts on downtime, public status page

## Step 1: Choose Monitoring Service

### Option A: UptimeRobot (Recommended for Free Tier)

**Free Tier:**
- 50 monitors
- 5-minute check intervals
- Email alerts
- Basic status page
- **Cost:** Free

**Setup:**
1. Sign up at https://uptimerobot.com
2. Verify email address
3. Navigate to Dashboard → Add New Monitor

### Option B: Better Uptime (Recommended for Open Source)

**Free Tier:**
- 10 monitors
- 1-minute check intervals
- Email + Slack alerts
- Custom status page
- **Cost:** Free (self-hosted) or paid (hosted)

**Setup:**
1. Sign up at https://betteruptime.com (hosted) or self-host
2. Create account
3. Navigate to Monitors → Add Monitor

### Option C: Cloudflare Health Checks

**Features:**
- Native Cloudflare integration
- 1-minute intervals
- Email alerts
- **Cost:** Included with Cloudflare Workers

**Setup:**
1. Cloudflare Dashboard → Workers & Pages → lornu-ai
2. Navigate to Health Checks section
3. Create health check

## Step 2: Configure Monitors

### Monitor 1: Frontend (lornu.ai)

**Configuration:**
- **Type:** HTTP(s) Monitor
- **URL:** `https://lornu.ai/`
- **Method:** GET
- **Expected Status:** 200
- **Check Interval:** 1 minute (or 5 minutes for free tier)
- **Timeout:** 30 seconds
- **Alert Threshold:** Alert after 2 consecutive failures

**Advanced Settings:**
- **Keyword Monitoring:** Optional - check for specific text in response (e.g., "LornuAI")
- **SSL Certificate Monitoring:** Enable to alert on certificate expiration

### Monitor 2: Health API (lornu.ai/api/health)

**Configuration:**
- **Type:** HTTP(s) Monitor
- **URL:** `https://lornu.ai/api/health`
- **Method:** GET
- **Expected Status:** 200
- **Expected Response Body:** `{"status":"ok"}` (JSON)
- **Check Interval:** 1 minute (or 5 minutes for free tier)
- **Timeout:** 10 seconds (lightweight endpoint)
- **Alert Threshold:** Alert after 2 consecutive failures

**Advanced Settings:**
- **Keyword Monitoring:** Check for `"status":"ok"` in response
- **Content-Type:** Verify `application/json` header

## Step 3: Configure Alerting

### Email Alerts (Default)

**Setup:**
1. In monitoring service dashboard, go to Alert Contacts
2. Add email address(es) for SRE team
3. Configure alert preferences:
   - **Alert on:** Down (service unavailable)
   - **Alert after:** 2 consecutive failures
   - **Alert frequency:** Once per incident (avoid spam)

### Slack Integration (Recommended)

**UptimeRobot:**
1. Go to Alert Contacts → Add Alert Contact
2. Select "Slack"
3. Create Slack webhook URL:
   - Slack Workspace → Apps → Incoming Webhooks
   - Create webhook for #sre-alerts channel
   - Copy webhook URL
4. Paste webhook URL in UptimeRobot
5. Test alert

**Better Uptime:**
1. Go to Integrations → Slack
2. Connect Slack workspace
3. Select channel for alerts
4. Configure alert preferences

### PagerDuty Integration (Optional, for Critical Alerts)

**Setup:**
1. Create PagerDuty service
2. Add monitoring service integration
3. Configure escalation policies
4. Test alert routing

## Step 4: Set Up Status Page

### Option A: UptimeRobot Status Page

**Setup:**
1. Dashboard → Status Pages → Create Status Page
2. Configure:
   - **Page Title:** LornuAI Status
   - **Page URL:** `status.lornu.ai` (or custom subdomain)
   - **Theme:** Match brand colors
3. Add Components:
   - **Component 1:** "LornuAI Frontend"
     - Link to Frontend Monitor
   - **Component 2:** "Health API"
     - Link to Health API Monitor
4. Configure DNS:
   - Add CNAME record: `status.lornu.ai` → `status.uptimerobot.com`
   - Wait for DNS propagation (up to 24 hours)

### Option B: Better Uptime Status Page

**Setup:**
1. Dashboard → Status Pages → Create Status Page
2. Configure:
   - **Page Title:** LornuAI Status
   - **Custom Domain:** `status.lornu.ai`
3. Add Components:
   - **Component 1:** "LornuAI Frontend"
   - **Component 2:** "Health API"
4. Link monitors to components
5. Configure DNS:
   - Add CNAME record: `status.lornu.ai` → `status.betteruptime.com`
   - Or use A record if provided

### Option C: Cloudflare Status Page

**Setup:**
1. Cloudflare Dashboard → Status Page (if available)
2. Create status page
3. Link to health checks
4. Configure DNS in Cloudflare Dashboard

## Step 5: DNS Configuration

### Cloudflare DNS Setup

1. Log in to Cloudflare Dashboard
2. Select `lornu.ai` domain
3. Go to DNS → Records
4. Add CNAME record:
   - **Name:** `status`
   - **Target:** `status.uptimerobot.com` (or your status page provider)
   - **Proxy status:** DNS only (gray cloud)
   - **TTL:** Auto
5. Save and wait for propagation

### Verify DNS

```bash
# Check DNS resolution
dig status.lornu.ai CNAME

# Or use online tool
# https://dnschecker.org
```

## Step 6: Test Monitoring

### Test Health Endpoint

```bash
# Test health endpoint
curl https://lornu.ai/api/health
# Expected: {"status":"ok"}

# Test with status code
curl -I https://lornu.ai/api/health
# Expected: HTTP/2 200
```

### Test Frontend

```bash
# Test frontend
curl -I https://lornu.ai/
# Expected: HTTP/2 200
```

### Test Alerting

1. Temporarily break health endpoint (or use test alert feature)
2. Verify alert is received via email/Slack
3. Verify status page shows incident
4. Restore endpoint
5. Verify alert for resolution

## Step 7: Documentation

### Update Footer Link

The footer already includes a link to `https://status.lornu.ai`. Once DNS is configured, this link will work.

### Create Incident Workflow

See `INCIDENT_WORKFLOW.md` for detailed incident response procedures.

## Monitoring Best Practices

1. **Check Intervals:**
   - Production: 1 minute (if available)
   - Free tier: 5 minutes (acceptable)

2. **Alert Thresholds:**
   - Alert after 2 consecutive failures (avoid false positives)
   - Use exponential backoff for repeated alerts

3. **Maintenance Windows:**
   - Pause monitors during scheduled maintenance
   - Document maintenance in status page

4. **Status Page Updates:**
   - Update status page during incidents
   - Post-mortem updates after resolution

5. **Regular Review:**
   - Review alert patterns monthly
   - Adjust thresholds based on false positive rate
   - Update runbooks based on incidents

## Troubleshooting

### Monitor Shows False Positives

- **Check timeout settings:** Increase timeout if service is slow
- **Check alert threshold:** Increase from 1 to 2 failures
- **Check network:** Verify monitoring service can reach endpoint

### Status Page Not Updating

- **Check DNS:** Verify CNAME record is correct
- **Check propagation:** Wait up to 24 hours for DNS
- **Check service:** Verify monitors are linked to components

### Alerts Not Received

- **Check spam folder:** Email alerts may be filtered
- **Check webhook:** Verify Slack webhook URL is correct
- **Test alert:** Use service's test alert feature

## Next Steps

1. ✅ Choose monitoring service
2. ✅ Set up monitors
3. ✅ Configure alerting
4. ✅ Set up status page
5. ✅ Configure DNS
6. ✅ Test monitoring
7. ✅ Document incident workflow

## Resources

- [UptimeRobot Documentation](https://uptimerobot.com/api/)
- [Better Uptime Documentation](https://betteruptime.com/docs)
- [Cloudflare Health Checks](https://developers.cloudflare.com/health-checks/)
- [Issue #66](https://github.com/lornu-ai/lornu-ai/issues/66)
