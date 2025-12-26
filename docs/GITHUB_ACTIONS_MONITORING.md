# GitHub Actions Synthetic Monitoring

This document describes Lornu AI's cost-optimized synthetic monitoring approach using GitHub Actions and BetterStack.

## Overview

**Monitoring Strategy:** GHA-to-Heartbeat Pattern  
**Cost:** ~$5/month (vs. $60/month SaaS monitoring)  
**Savings:** 92% reduction in monitoring costs  
**Coverage:** Production environment health checks every 10 minutes  

## Architecture

### Components

```
GitHub Actions (every 10 min)
    ↓
Run Playwright Tests
    ↓
Success: Send Heartbeat → BetterStack Monitor (alerts if missed)
Failure: Skip heartbeat → BetterStack triggers alert after timeout
    ↓
Publish HTML Report → GitHub Pages
```

### Cost Breakdown

| Component | Cost | Notes |
|-----------|------|-------|
| GitHub Actions | ~$4-5/mo | 10-min cron × 1440/day × 30 days ≈ 0.2M minutes |
| BetterStack Heartbeat | Free | Free monitoring monitors (unlimited) |
| GitHub Pages | Free | Included with org account |
| **Total** | **~$5/mo** | **92% cheaper than SaaS** |

## Setup

### 1. Create BetterStack Heartbeat Monitor

1. Go to [uptime.betterstack.com](https://uptime.betterstack.com)
2. Create new Monitor → "Heartbeat Monitor"
3. Get the **Heartbeat URL** (looks like: `https://uptime.betterstack.com/api/v1/heartbeat/...`)
4. Note: This is **free** and supports **unlimited heartbeat monitors**

### 2. Configure GitHub Secrets

Add these secrets to your GitHub repository:

| Secret | Value | Where to Get |
|--------|-------|--------------|
| `BETTERSTACK_HEARTBEAT_URL` | BetterStack heartbeat endpoint | BetterStack dashboard |
| `GITHUB_TOKEN` | Auto-provided by Actions | (automatically available) |

```bash
# CLI example
gh secret set BETTERSTACK_HEARTBEAT_URL --body "https://uptime.betterstack.com/api/v1/heartbeat/your-key"
```

### 3. Deploy Workflow

The workflow `.github/workflows/synthetic-cron.yml` includes:

- **Schedule**: Every 10 minutes (`*/10 * * * *`)
- **Test File**: `apps/web/tests/e2e/betterstack-monitoring.spec.ts`
- **On Success**: POST heartbeat to BetterStack
- **On Failure**: Skip heartbeat (BetterStack alerts after 60-90 sec timeout)
- **Report**: Publish to GitHub Pages at `/reports/{run_number}`

## Monitoring Tests

### betterstack-monitoring.spec.ts

Tests run against production (`https://lornu.ai`):

1. **Home page loads** - Verifies page title, nav visibility
2. **API health endpoint** - Checks `/api/health` returns `{"status": "ok"}`
3. **Critical navigation** - Tests Terms & Privacy pages work
4. **Contact form** - Verifies form fields are accessible
5. **No JavaScript errors** - Captures console/page errors
6. **Static assets load** - Validates CSS, JS, images, fonts load

### Test Results

- **Artifact Retention**: 90 days default (GitHub Actions)
- **HTML Reports**: Published to [lornu-ai.github.io/lornu-ai](https://lornu-ai.github.io/lornu-ai)
- **Report URL Pattern**: `https://lornu-ai.github.io/lornu-ai/reports/{run_number}/index.html`

## Alerting Strategy

### How It Works

```
Test Execution
  ↓
  ├─ PASS → POST heartbeat to BetterStack
  │         └─ BetterStack expects heartbeat every 10 min
  │
  └─ FAIL → Skip heartbeat
            └─ After 60-90 sec, BetterStack timeout triggers alert
```

### Alert Configuration

1. Go to [BetterStack Dashboard](https://uptime.betterstack.com)
2. Select your Heartbeat Monitor
3. Configure Alert Policy:
   - **On Missed Heartbeat**: Alert immediately
   - **Notification Channels**: Email, Slack, PagerDuty, etc.
   - **Escalation**: Configure escalation policy

## GitHub Pages Dashboard

### Live Status

The HTML Playwright report is published to GitHub Pages after every test run:

```
URL: https://lornu-ai.github.io/lornu-ai/reports/{run_number}/
Latest: https://lornu-ai.github.io/lornu-ai/
```

### Features

- **Lornu AI Logo**: Injected into report header
- **Test Results**: Full Playwright report with screenshots
- **Status Timeline**: Last 30 runs available
- **Public Visibility**: "Build in Public" transparency

### Adding Badge to README

```markdown
[![Synthetic Monitoring](https://img.shields.io/badge/monitoring-live-green?logo=github-actions)](https://lornu-ai.github.io/lornu-ai/)
```

## Maintenance

### Manual Trigger

Run tests manually:

```bash
gh workflow run synthetic-cron.yml -f ref=main
```

Or via GitHub UI:
1. Go to Actions → Synthetic Monitoring - BetterStack Heartbeat
2. Click "Run workflow" → "Run workflow"

### Monitoring the Monitor

Check if heartbeats are being received:

1. BetterStack Dashboard → Heartbeat Monitor
2. Look for "Last Heartbeat" timestamp
3. Should update every 10 minutes during business hours

### Debugging Failed Tests

1. Go to GitHub Actions → Synthetic Monitoring workflow
2. Click failed run
3. View "Run Synthetic Monitoring Tests" step
4. Download "playwright-report" artifact
5. Open `index.html` locally to see failures

## Cost Analysis vs Alternatives

| Service | Cost/Month | Type | Features |
|---------|-----------|------|----------|
| **GHA + BetterStack** | ~$5 | DIY | Tests + heartbeat + dashboards |
| BetterStack (paid) | $60+ | SaaS | Limited synthetics, expensive |
| DataDog | $200+ | SaaS | Expensive, over-featured |
| Uptime.com | $150+ | SaaS | Vendor lock-in |
| New Relic | $250+ | SaaS | Complex, costly |

**Our Solution**: 92% cheaper, 100% transparent, owned by org

## Next Steps

1. ✅ Create BetterStack Heartbeat Monitor (free)
2. ✅ Add `BETTERSTACK_HEARTBEAT_URL` secret to GitHub
3. ✅ Deploy `.github/workflows/synthetic-cron.yml`
4. ✅ Verify first test run succeeds
5. ✅ Configure BetterStack alerting policy
6. ✅ Add status badge to README
7. Monitor Heartbeat Monitor status in BetterStack dashboard

## References

- [BetterStack Heartbeat Monitors](https://betterstack.com/heartbeat-monitoring)
- [Playwright HTML Reports](https://playwright.dev/docs/test-reporters#html-reporter)
- [GitHub Actions Workflows](https://docs.github.com/en/actions)
- [GitHub Pages Deployment](https://docs.github.com/en/pages)
