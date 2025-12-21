# Uptime Monitoring & Status Page Implementation Plan

**Issue:** [#66 - Production Uptime and Status Page Implementation](https://github.com/lornu-ai/lornu-ai/issues/66)
**Status:** Partially Complete - Code Implementation Done, External Configuration Pending
**PR:** [#67 - feat: add health check endpoint and status page link](https://github.com/lornu-ai/lornu-ai/pull/67)

## ✅ Completed

### 1. Health Check Endpoint (`/api/health`)
- ✅ Implemented `handleHealthAPI()` function in `apps/web/worker.ts`
- ✅ Returns `200 OK` with `{ status: 'ok' }` JSON response
- ✅ Lightweight, no external dependencies, fast response (< 10ms)
- ✅ Suitable for 1-minute interval monitoring checks
- ✅ Comprehensive test suite (4 tests) - all passing

### 2. Status Page Link
- ✅ Added link to `https://status.lornu.ai` in footer (`apps/web/src/pages/Home.tsx`)
- ✅ Placed alongside Privacy, Terms, Security links
- ✅ Opens in new tab with proper security attributes

### 3. Performance Monitoring
- ✅ Cloudflare Performance Reporting configured
- ✅ Monitoring: `https://lornu.ai/` (Desktop, US Central)
- ✅ Available at: [Cloudflare Dashboard](https://dash.cloudflare.com/{account-id}/lornu.ai/speed/test/lornu.ai%2F/history/desktop/us-central1)
- ✅ Tracks Core Web Vitals and performance metrics

## 📋 Pending (External Configuration)

### Subdomain Decision
**No new subdomain needed for the worker.** The health endpoint is accessible at:
- `https://lornu.ai/api/health` (already working)

### Status Page Options

#### Option 1: External Status Page Service (Recommended)
**Services to consider:**
- UptimeRobot (free tier available)
- Better Uptime (open source, self-hosted option)
- Cloudflare Status Pages (if available)
- Statuspage.io (Atlassian)

**Setup Steps:**
1. Sign up for chosen status page service
2. Configure DNS: Point `status.lornu.ai` CNAME to service provider
3. Set up monitors:
   - **Frontend Monitor:** `https://lornu.ai/` (check for HTTP 200)
   - **Health API Monitor:** `https://lornu.ai/api/health` (check for HTTP 200 + JSON body `{ status: 'ok' }`)
4. Configure alerting:
   - Alert after 2 consecutive failures
   - Notify SRE team via email/Slack/PagerDuty
5. Link monitors to status page components:
   - Component: "Lornuai Frontend"
   - Component: "RAG Core API" (or "Health API")

**Pros:**
- Less maintenance
- Built-in monitoring integration
- Incident management features
- Matches issue requirements

#### Option 2: Self-Hosted Status Page
If hosting status page in the same worker:

**Option A: Route-based (No subdomain)**
- Add `/status` route to worker
- Accessible at `lornu.ai/status`
- Would need to build status page UI

**Option B: Subdomain-based**
- Add to `wrangler.toml`:
  ```toml
  [[routes]]
  pattern = "status.lornu.ai"
  custom_domain = true
  ```
- Configure DNS in Cloudflare Dashboard
- Build status page UI in React

**Pros:**
- Full control
- Custom branding
- No external dependencies

**Cons:**
- More development work
- Need to build incident management UI
- More maintenance

## 🎯 Recommended Next Steps

1. **Choose Status Page Service** (recommend Option 1 - External Service)
2. **Set up External Monitoring:**
   - Create account on chosen service
   - Configure DNS for `status.lornu.ai`
   - Set up two monitors (Frontend + Health API)
   - Configure alerting (email/Slack/PagerDuty)
3. **Test Monitoring:**
   - Verify health endpoint responds correctly
   - Test alerting by temporarily breaking endpoint
   - Verify status page updates correctly
4. **Document Incident Workflow:**
   - Create runbook for updating status page during incidents
   - Document alert escalation process

## 📝 Acceptance Criteria Status

- ✅ **Health Endpoint:** `/api/health` returns `200 OK` with minimal payload
- ✅ **Status Page Link:** Footer includes link to status page
- ✅ **Setup Documentation:** Comprehensive guides for monitoring setup and incident workflow
- ⏳ **Monitoring Active:** External monitoring service pinging endpoints (pending - ready to configure)
- ⏳ **Alert Channel:** Alerts routed to SRE/Operations channel (pending - ready to configure)
- ⏳ **Status Page Live:** Public status page displaying operational status (pending - ready to configure)
- ✅ **Incident Workflow:** Documented workflow for manual status page updates

## 🔗 Related Files

- `apps/web/worker.ts` - Health endpoint implementation
- `apps/web/src/pages/Home.tsx` - Footer with status page link
- `apps/web/src/worker.test.ts` - Health endpoint tests
- `apps/web/wrangler.toml` - Worker configuration (no changes needed for external status page)
- `docs/UPTIME_MONITORING_SETUP.md` - Step-by-step setup guide for external monitoring
- `docs/INCIDENT_WORKFLOW.md` - Incident response procedures and runbooks

## 📚 Resources

- [Issue #66](https://github.com/lornu-ai/lornu-ai/issues/66)
- [PR #67](https://github.com/lornu-ai/lornu-ai/pull/67)
- [UptimeRobot Documentation](https://uptimerobot.com/api/)
- [Better Uptime Documentation](https://betteruptime.com/docs)
- [Cloudflare Health Checks](https://developers.cloudflare.com/health-checks/)

---

**Last Updated:** 2025-12-15
**Next Steps:**
1. Review `docs/UPTIME_MONITORING_SETUP.md` for detailed setup instructions
2. Choose monitoring service (UptimeRobot recommended for free tier)
3. Follow setup guide to configure monitors and status page
4. Configure DNS for `status.lornu.ai` subdomain
5. Test monitoring and alerting
