# GitHub Actions Synthetic Monitoring

Cost-optimized synthetic monitoring using GitHub Actions and BetterStack.

## Overview

**Strategy:** GHA-to-Heartbeat Pattern
**Cost:** ~$5/month (vs. $60/month SaaS)
**Savings:** 92% reduction
**Frequency:** Every 10 minutes

## Architecture

```
GitHub Actions (10-min cron)
    ↓
Run Playwright Tests
    ↓
Success: Send Heartbeat → BetterStack (free monitor)
Failure: Skip heartbeat → BetterStack alert after timeout
    ↓
Publish HTML Report → GitHub Pages
```

## Setup

### 1. Create BetterStack Heartbeat Monitor

1. Go to https://uptime.betterstack.com
2. Create new Monitor → "Heartbeat Monitor"
3. Get the **Heartbeat URL** (free, unlimited monitors)

### 2. Configure GitHub Secret

Add to repository settings:
```bash
gh secret set BETTERSTACK_HEARTBEAT_URL --body "https://uptime.betterstack.com/api/v1/heartbeat/YOUR-KEY"
```

### 3. Workflow Deployed

- **File:** `.github/workflows/synthetic-cron.yml`
- **Schedule:** Every 10 minutes (`*/10 * * * *`)
- **Test File:** `apps/web/tests/e2e/betterstack-monitoring.spec.ts`
- **Reports:** Published to GitHub Pages (90-day retention)

## Cost Breakdown

| Component | Cost |
|-----------|------|
| GitHub Actions | ~$5/mo |
| BetterStack Heartbeat | FREE |
| GitHub Pages | FREE |
| **Total** | **~$5/mo** |

**vs. Competitors:**
- BetterStack SaaS: $60+/mo
- DataDog: $200+/mo
- New Relic: $250+/mo

## Tests Covered

1. Homepage loads correctly
2. API health endpoint responds
3. Critical navigation works
4. Contact form accessible
5. No JavaScript errors
6. Static assets load successfully

## Monitoring

- **Status:** Check BetterStack dashboard for heartbeat timestamps
- **Alerts:** Configure in BetterStack (email, Slack, PagerDuty, etc.)
- **Dashboard:** https://lornu-ai.github.io/lornu-ai/

## References

- [BetterStack Heartbeat](https://betterstack.com/heartbeat-monitoring)
- [GitHub Actions Workflows](https://docs.github.com/en/actions)
- [Playwright HTML Reports](https://playwright.dev/docs/test-reporters)
