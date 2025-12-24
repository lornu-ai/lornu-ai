# Metric & Synthetic Monitoring Guide

This guide details the setup for **Synthetic Monitoring** using [Better Stack](https://betterstack.com) (formerly Uptime).

## 🎯 Objective
Ensure critical user journeys are functional by simulating real user traffic 24/7.

**Critical Journey**: `Login` -> `View Thread` -> `Verify AI Output`

## 🛠️ Synthetic Monitor Setup

### 1. Prerequisites
- **Better Stack Account**: Access to Team `t483057`.
- **Monitor User**: A dedicated user account in the environment (Staging/Prod).
  - Email: `monitor@lornu.ai`
  - Password: (Stored in Better Stack Vault / Env Vars)

### 2. Monitor Configuration
Create a new **Playwright** monitor in Better Stack:

1.  **Name**: `Lornu AI - Critical Journey (Prod)`
2.  **Frequency**: 5 minutes
3.  **Locations**: US East (N. Virginia), US West (California)
4.  **Device**: Desktop Chrome
5.  **Environment Variables**:
    - `BASE_URL`: `https://lornu.ai`
    - `MONITOR_EMAIL`: `monitor@lornu.ai`
    - `MONITOR_PASSWORD`: `[REDACTED]`

### 3. The Script
Copy the content of `apps/web/tests/e2e/synthetic.spec.ts` into the Better Stack editor.
*Note: Better Stack uses a slightly different wrapper. Adapt roughly as follows:*

```javascript
// Better Stack wrapper structure
module.exports = async function run(page, request) {
  const BASE_URL = process.env.BASE_URL || 'https://lornu.ai';

  // 1. Visit Home
  await page.goto(BASE_URL);
  await page.waitForLoadState('networkidle');

  // 2. Validate Public Content
  const getStarted = page.locator('button:has-text("Get Started")').first();
  await getStarted.waitFor();

  // 3. (Future) Auth Flow
  // await page.click('text=Sign In');
  // ... see synthetic.spec.ts for logic
};
```

### 4. Alerting Policy
Ensure the monitor is linked to the active on-call schedule.
- **Slack**: Channel `#ops-alerts`
- **Email**: DevOps distribution list
- **Escalation**: PagerDuty (if critical)

## 🌱 Seeding Test Data

We use `uv` to manage the data seeding script. This allows us to reset the monitor user's state if it gets corrupted or locked.

**Run the Seeder:**
```bash
# Requires ADMIN_API_KEY environment variable
cd scripts/monitoring
uv run seed_monitor.py
```

## 🚨 Troubleshooting
If the monitor fails:
1. Check the Screenshot & Video in Better Stack.
2. Verify if the `monitor@lornu.ai` account is locked.
3. Run the E2E test locally:
   ```bash
   cd apps/web
   bun run test:e2e
   ```
