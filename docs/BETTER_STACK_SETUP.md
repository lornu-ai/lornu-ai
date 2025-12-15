# Better Stack (Better Uptime) Setup Guide

**Status:** Active Setup
**Last Updated:** 2025-12-15
**Account:** Access your Better Stack dashboard at https://uptime.betterstack.com

## Overview

This guide walks through setting up uptime monitoring in Better Stack for `lornu.ai`.

## Prerequisites

- ✅ Better Stack account created
- ✅ Health endpoint: `https://lornu.ai/api/health`
- ✅ Frontend: `https://lornu.ai/`

## Step 1: Create Monitors

### Monitor 1: Frontend (lornu.ai)

1. **Navigate to Monitors:**
   - Log in to your Better Stack account
   - Go to the Monitors section in your dashboard
   - Click **"Add Monitor"** or **"New Monitor"**

2. **Monitor Configuration:**
   - **Monitor Type:** HTTP(s)
   - **URL:** `https://lornu.ai/`
   - **Method:** GET
   - **Expected Status Code:** 200
   - **Check Interval:** 1 minute (or 5 minutes for free tier)
   - **Timeout:** 30 seconds
   - **Retry Policy:** Alert after 2 consecutive failures

3. **Advanced Settings:**
   - **Follow Redirects:** Yes
   - **SSL Certificate Monitoring:** Enable (alert on certificate expiration)
   - **Keyword Monitoring (Optional):** Check for "LornuAI" in response body
   - **Request Headers:** None required

4. **Save Monitor:**
   - **Name:** "LornuAI Frontend"
   - **Description:** "Main website frontend at lornu.ai"
   - Click **"Create Monitor"**

### Monitor 2: Health API (lornu.ai/api/health)

1. **Add Another Monitor:**
   - Click **"Add Monitor"** again

2. **Monitor Configuration:**
   - **Monitor Type:** HTTP(s)
   - **URL:** `https://lornu.ai/api/health`
   - **Method:** GET
   - **Expected Status Code:** 200
   - **Check Interval:** 1 minute (or 5 minutes for free tier)
   - **Timeout:** 10 seconds (lightweight endpoint)
   - **Retry Policy:** Alert after 2 consecutive failures

3. **Advanced Settings:**
   - **Response Body Validation:**
     - **Keyword:** `"status":"ok"` (or `{"status":"ok"}`)
     - **Match Type:** Contains
   - **Content-Type:** Verify `application/json`
   - **SSL Certificate Monitoring:** Enable

4. **Save Monitor:**
   - **Name:** "LornuAI Health API"
   - **Description:** "Health check endpoint for uptime monitoring"
   - Click **"Create Monitor"**

## Step 2: Configure Alerting

### Email Alerts

1. **Navigate to Alerting:**
   - Go to Settings → Alert Contacts (or Integrations)
   - Click **"Add Contact"**

2. **Add Email:**
   - **Type:** Email
   - **Email Address:** Your SRE team email(s)
   - **Alert Preferences:**
     - Alert on: Down (service unavailable)
     - Alert after: 2 consecutive failures
     - Alert frequency: Once per incident

3. **Assign to Monitors:**
   - Select both monitors
   - Assign email contact
   - Save

### Slack Integration (Recommended)

1. **Create Slack Webhook:**
   - Go to Slack Workspace → Apps → Incoming Webhooks
   - Create webhook for `#sre-alerts` channel (or your preferred channel)
   - Copy webhook URL

2. **Add Slack Integration:**
   - In Better Stack: Settings → Integrations → Slack
   - Paste webhook URL
   - Configure:
     - **Channel:** #sre-alerts
     - **Alert on:** Down, Up (service restored)
     - **Alert after:** 2 consecutive failures

3. **Assign to Monitors:**
   - Select both monitors
   - Assign Slack integration
   - Save

### PagerDuty Integration (Optional, for Critical Alerts)

1. **Create PagerDuty Service:**
   - In PagerDuty, create new service
   - Add Better Stack integration

2. **Add PagerDuty Integration:**
   - In Better Stack: Settings → Integrations → PagerDuty
   - Connect PagerDuty account
   - Select service
   - Configure escalation policies

3. **Assign to Monitors:**
   - Select both monitors
   - Assign PagerDuty integration
   - Save

## Step 3: Set Up Status Page

1. **Navigate to Status Pages:**
   - Go to Status Pages section
   - Click **"Create Status Page"**

2. **Status Page Configuration:**
   - **Page Title:** "LornuAI Status"
   - **Page URL:** `status.lornu.ai` (custom domain)
   - **Theme:** Match brand colors (if available)
   - **Language:** English

3. **Add Components:**
   - **Component 1:** "LornuAI Frontend"
     - Link to "LornuAI Frontend" monitor
     - Description: "Main website and user interface"
   - **Component 2:** "Health API"
     - Link to "LornuAI Health API" monitor
     - Description: "Health check endpoint for monitoring"

4. **Save Status Page**

## Step 4: Configure DNS for Status Page

### Cloudflare DNS Setup

1. **Log in to Cloudflare Dashboard:**
   - Go to: https://dash.cloudflare.com
   - Select `lornu.ai` domain

2. **Add CNAME Record:**
   - Go to DNS → Records
   - Click **"Add Record"**
   - **Type:** CNAME
   - **Name:** `status`
   - **Target:** `status.betterstack.com` (or the domain provided by Better Stack)
   - **Proxy status:** DNS only (gray cloud - turn off proxy)
   - **TTL:** Auto
   - Click **"Save"**

3. **Verify DNS:**
   ```bash
   # Check DNS resolution
   dig status.lornu.ai CNAME

   # Or use online tool
   # https://dnschecker.org
   ```

4. **Wait for Propagation:**
   - DNS changes can take up to 24 hours
   - Usually propagates within 1-2 hours

## Step 5: Test Monitoring

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

1. **Temporarily Break Health Endpoint:**
   - Or use Better Stack's "Test Alert" feature
   - Verify alert is received via email/Slack

2. **Verify Status Page:**
   - Check that status page shows incident
   - Verify components show correct status

3. **Restore Endpoint:**
   - Verify alert for resolution
   - Verify status page updates

## Step 6: Verify Setup

### Checklist

- [ ] Both monitors created and active
- [ ] Monitors showing "Up" status (green)
- [ ] Email alerts configured and tested
- [ ] Slack integration configured (if using)
- [ ] Status page created and accessible
- [ ] DNS configured for `status.lornu.ai`
- [ ] Status page link in footer works (already added)
- [ ] Test alert received successfully

### Monitor Status

Check monitor status in your Better Stack dashboard:
- Navigate to the Monitors section
- Verify both monitors show "Up" status (green)

Expected status:
- ✅ **LornuAI Frontend:** Up (green)
- ✅ **LornuAI Health API:** Up (green)

## Monitoring Best Practices

1. **Check Intervals:**
   - Production: 1 minute (if available in your plan)
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
   - Review alert patterns weekly
   - Adjust thresholds based on false positive rate
   - Update runbooks based on incidents

## Troubleshooting

### Monitor Shows False Positives

- **Check timeout settings:** Increase timeout if service is slow
- **Check alert threshold:** Increase from 1 to 2 failures
- **Check network:** Verify Better Stack can reach endpoint

### Status Page Not Updating

- **Check DNS:** Verify CNAME record is correct
- **Check propagation:** Wait up to 24 hours for DNS
- **Check service:** Verify monitors are linked to components

### Alerts Not Received

- **Check spam folder:** Email alerts may be filtered
- **Check webhook:** Verify Slack webhook URL is correct
- **Test alert:** Use Better Stack's test alert feature

## Next Steps

1. ✅ Create both monitors
2. ✅ Configure alerting (email + Slack)
3. ✅ Set up status page
4. ✅ Configure DNS for `status.lornu.ai`
5. ✅ Test monitoring and alerting
6. ✅ Verify status page is accessible

## Resources

- [Better Stack Dashboard](https://uptime.betterstack.com) - Log in to access your monitors
- [Better Stack Documentation](https://betterstack.com/docs)
- [Issue #66](https://github.com/lornu-ai/lornu-ai/issues/66)
- [Uptime Monitoring Setup Guide](./UPTIME_MONITORING_SETUP.md)
