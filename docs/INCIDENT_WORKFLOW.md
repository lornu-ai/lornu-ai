# Incident Response Workflow

**Status:** Active
**Last Updated:** 2025-12-15

## Overview

This document outlines the workflow for responding to incidents detected by uptime monitoring and updating the public status page.

## Incident Detection

### Automatic Detection

Incidents are automatically detected by:
- **Uptime Monitoring Service:** Alerts when monitors fail (2 consecutive failures)
- **Alert Channels:**
  - Email to SRE team
  - Slack #sre-alerts channel
  - PagerDuty (if configured)

### Alert Information

Each alert includes:
- **Service:** Frontend or Health API
- **Status:** Down/Up
- **Timestamp:** When incident started/resolved
- **Response Time:** If available
- **Error Details:** HTTP status code, error message

## Incident Response Steps

### 1. Acknowledge Alert (Within 5 minutes)

**Actions:**
- [ ] Acknowledge alert in monitoring service
- [ ] Post in Slack #incidents channel
- [ ] Assign incident owner

**Slack Template:**
```
🚨 INCIDENT: [Service Name] - [Brief Description]
Owner: @username
Status: Investigating
```

### 2. Investigate (Within 15 minutes)

**Actions:**
- [ ] Check Cloudflare Dashboard for worker errors
- [ ] Review worker logs in Cloudflare Dashboard
- [ ] Check health endpoint: `curl https://lornu.ai/api/health`
- [ ] Check frontend: `curl -I https://lornu.ai/`
- [ ] Review recent deployments
- [ ] Check external dependencies (Resend API, etc.)

**Investigation Checklist:**
- [ ] Worker is running
- [ ] Assets are being served
- [ ] API endpoints responding
- [ ] No recent code changes
- [ ] External services operational

### 3. Update Status Page

**Actions:**
- [ ] Log in to status page service
- [ ] Create incident
- [ ] Update affected components:
  - **LornuAI Frontend** (if frontend down)
  - **Health API** (if API down)
- [ ] Set status: **Investigating** → **Identified** → **Monitoring**

**Status Page Update Template:**
```
Title: [Service Name] - [Issue Description]
Status: Investigating
Affected Components: [Component Names]
Started: [Timestamp]
Description: We're currently investigating an issue affecting [service]. We'll provide updates as we learn more.
```

### 4. Resolve Incident

**Actions:**
- [ ] Identify root cause
- [ ] Implement fix
- [ ] Verify fix:
  - Health endpoint returns 200
  - Frontend loads correctly
  - Monitors show green
- [ ] Update status page: **Resolved**
- [ ] Post resolution in Slack

**Resolution Template:**
```
✅ RESOLVED: [Service Name] - [Brief Description]
Duration: [X minutes/hours]
Root Cause: [Brief explanation]
Fix Applied: [What was done]
Prevention: [How to prevent recurrence]
```

### 5. Post-Mortem (Within 48 hours)

**Actions:**
- [ ] Schedule post-mortem meeting
- [ ] Document:
  - Timeline of events
  - Root cause analysis
  - Impact assessment
  - Actions taken
  - Prevention measures
- [ ] Update runbooks if needed
- [ ] Share learnings with team

## Status Page Updates

### Status Levels

1. **Operational** (Green)
   - All systems operational
   - No issues detected

2. **Degraded Performance** (Yellow)
   - Service is operational but experiencing issues
   - Some users may be affected
   - Example: Slow response times

3. **Partial Outage** (Orange)
   - Some components are down
   - Limited functionality available
   - Example: API down but frontend works

4. **Major Outage** (Red)
   - Service is completely unavailable
   - All users affected
   - Example: Frontend completely down

### Update Frequency

- **During Incident:** Update every 15-30 minutes
- **After Resolution:** Final update within 1 hour
- **Post-Mortem:** Update with incident summary

### Update Template

```
[Status] - [Component Name]

[Brief description of current status]

[What users can expect]

[Estimated time to resolution, if known]

Last updated: [Timestamp]
```

## Communication Guidelines

### Internal Communication

**Slack Channels:**
- **#sre-alerts:** Automated alerts
- **#incidents:** Incident coordination
- **#engineering:** Technical discussions

**Communication Rules:**
- Acknowledge alerts within 5 minutes
- Provide updates every 15-30 minutes during incidents
- Post resolution within 1 hour

### External Communication

**Status Page:**
- Update status page immediately when incident starts
- Provide clear, user-friendly updates
- Avoid technical jargon
- Set expectations for resolution time

**Social Media (if applicable):**
- Tweet/Post about major incidents
- Link to status page
- Provide regular updates

## Escalation Path

### Level 1: On-Call Engineer (0-30 minutes)
- Acknowledge alert
- Initial investigation
- Update status page

### Level 2: Senior Engineer (30-60 minutes)
- Deep investigation
- Coordinate fix
- Communication with stakeholders

### Level 3: Engineering Lead (60+ minutes)
- Strategic decisions
- Resource allocation
- External communication

### Level 4: CTO/VP Engineering (2+ hours)
- Major incidents only
- Business impact assessment
- Public communication

## Prevention Measures

### Proactive Monitoring

- [ ] Review alert patterns weekly
- [ ] Adjust thresholds based on false positives
- [ ] Monitor trends (response times, error rates)
- [ ] Set up predictive alerts

### Regular Maintenance

- [ ] Weekly health check review
- [ ] Monthly incident review
- [ ] Quarterly runbook updates
- [ ] Annual disaster recovery drill

### Code Quality

- [ ] Comprehensive testing before deployment
- [ ] Staging environment testing
- [ ] Gradual rollouts
- [ ] Feature flags for risky changes

## Runbooks

### Health Endpoint Down

**Symptoms:**
- `/api/health` returns non-200 status
- Monitor shows down

**Investigation:**
1. Check worker logs
2. Verify worker is deployed
3. Check for recent deployments
4. Review worker code

**Resolution:**
1. Rollback if recent deployment
2. Check worker configuration
3. Verify environment variables
4. Restart worker if needed

### Frontend Down

**Symptoms:**
- `lornu.ai/` returns non-200 status
- Frontend doesn't load

**Investigation:**
1. Check worker logs
2. Verify assets are built and deployed
3. Check Cloudflare cache
4. Review recent deployments

**Resolution:**
1. Clear Cloudflare cache
2. Verify build output
3. Check asset paths
4. Rollback if needed

### False Positive Alerts

**Symptoms:**
- Monitor shows down but service is up
- Intermittent failures

**Investigation:**
1. Check monitoring service status
2. Verify network connectivity
3. Review timeout settings
4. Check for rate limiting

**Resolution:**
1. Adjust timeout settings
2. Increase alert threshold
3. Whitelist monitoring IPs if needed
4. Contact monitoring service support

## Metrics to Track

- **MTTR (Mean Time To Resolution):** Target < 30 minutes
- **MTBF (Mean Time Between Failures):** Target > 99.9% uptime
- **Alert Response Time:** Target < 5 minutes
- **Status Page Update Time:** Target < 15 minutes

## Resources

- [Status Page](https://status.lornu.ai)
- [Monitoring Dashboard](https://uptimerobot.com) (or your service)
- [Cloudflare Dashboard](https://dash.cloudflare.com)
- [Issue #66](https://github.com/lornu-ai/lornu-ai/issues/66)
