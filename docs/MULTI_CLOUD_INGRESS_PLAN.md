# Multi-Cloud Ingress Implementation Plan

**Issue**: #297 - Epic: Multi-Cloud Ingress & Global Traffic Steering (Uptime-First)

## Overview

This plan breaks the epic into 4 focused PRs that can be merged incrementally.

---

## Phase 1: GCP Foundation (PR #1)

**Goal**: Establish GCP Terraform structure and core GXLB resources.

### Files to Create
```
terraform/gcp/
├── main.tf              # Provider, backend config
├── variables.tf         # Shared variables
├── lb.tf                # Global LB, forwarding rules, target proxy
├── ssl.tf               # Google-managed certificates
├── cdn.tf               # Cloud CDN configuration
└── outputs.tf           # LB IP, DNS name outputs
```

### Resources
- `google_compute_global_address` - Anycast IP
- `google_compute_global_forwarding_rule` - HTTPS forwarding
- `google_compute_target_https_proxy` - SSL termination
- `google_compute_url_map` - Routing rules
- `google_compute_managed_ssl_certificate` - Auto-provisioned certs
- `google_compute_backend_service` - Primary backend (Cloud Run/GKE)

### Acceptance Criteria
- [ ] Single Global Anycast IP provisioned
- [ ] Google-managed SSL certificate for `lornu.ai`
- [ ] Cloud CDN enabled for static assets

---

## Phase 2: AWS NLB for GXLB Integration (PR #2)

**Goal**: Configure AWS to accept traffic from Google GXLB.

### Files to Modify/Create
```
terraform/aws/production/
├── nlb.tf               # NEW: Network Load Balancer for GXLB
├── security_groups.tf   # UPDATE: Allow GXLB health check CIDRs
└── outputs.tf           # UPDATE: Export NLB DNS name
```

### Resources
- `aws_lb` (type: network) - Public NLB for GXLB backend
- `aws_lb_listener` - TCP/TLS listeners
- `aws_security_group_rule` - Allow Google GXLB CIDRs

### Google GXLB Health Check CIDRs
```hcl
# From: https://cloud.google.com/load-balancing/docs/health-check-concepts
variable "google_health_check_cidrs" {
  default = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]
}
```

### Acceptance Criteria
- [ ] NLB provisioned with public DNS
- [ ] Security groups allow GXLB health probes
- [ ] NLB routes to EKS ingress controller

---

## Phase 3: Internet NEGs & Cross-Cloud Health Checks (PR #3)

**Goal**: Connect GCP GXLB to AWS backend via Internet NEGs.

### Files to Create/Modify
```
terraform/gcp/
├── neg.tf               # NEW: Internet Network Endpoint Groups
├── health_checks.tf     # NEW: Cross-cloud health checks
└── lb.tf                # UPDATE: Add AWS backend service
```

### Resources
- `google_compute_global_network_endpoint_group` - Internet NEG
- `google_compute_global_network_endpoint` - AWS NLB endpoint
- `google_compute_health_check` - HTTP health check to `/health`
- `google_compute_backend_service` - AWS failover backend (weight: 0)

### Traffic Steering Configuration
```hcl
# Primary: GCP (weight: 100)
# Failover: AWS (weight: 0, failover_policy enabled)
resource "google_compute_backend_service" "primary" {
  backend {
    group           = google_compute_region_neg.gcp_primary.id
    capacity_scaler = 1.0
  }

  backend {
    group           = google_compute_global_network_endpoint_group.aws_failover.id
    capacity_scaler = 0.0  # Only used during failover
  }

  locality_lb_policy = "ROUND_ROBIN"
}
```

### Acceptance Criteria
- [ ] Internet NEG points to AWS NLB DNS
- [ ] Health checks probe AWS `/health` endpoint
- [ ] Traffic stays on GCP unless primary unhealthy

---

## Phase 4: Monitoring & Alerting (PR #4)

**Goal**: Integrate Better Stack monitoring and failover alerts.

### Files to Create
```
terraform/gcp/
└── monitoring.tf        # Cloud Monitoring alerts

terraform/shared/
└── betterstack.tf       # Better Stack integration (if using TF provider)
```

### Better Stack Configuration
- Playwright monitors for GXLB Anycast IP
- Uptime checks from multiple global regions
- Webhook alerts on failover events

### Cloud Monitoring Alerts
```hcl
resource "google_monitoring_alert_policy" "failover_triggered" {
  display_name = "GXLB Failover to AWS"
  combiner     = "OR"

  conditions {
    display_name = "Primary backend unhealthy"
    condition_threshold {
      filter          = "resource.type=\"https_lb_rule\" AND metric.type=\"loadbalancing.googleapis.com/https/backend_request_count\""
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = "60s"
    }
  }

  notification_channels = [google_monitoring_notification_channel.betterstack.id]
}
```

### Acceptance Criteria
- [ ] Better Stack monitors GXLB endpoint
- [ ] Alerts fire within 30s of failover
- [ ] Runbook documented for manual intervention

---

## Dependency Graph

```
PR #1 (GCP Foundation)
    │
    ├──► PR #2 (AWS NLB) ──► PR #3 (Internet NEGs)
    │                              │
    └──────────────────────────────┴──► PR #4 (Monitoring)
```

---

## Quick Wins (Can Start Immediately)

1. **Backend Health Endpoint** - Ensure `/health` returns ADK agent status
2. **GCP Project Setup** - Enable required APIs (Compute, CDN, Cloud Armor)
3. **Terraform State** - Configure GCP backend (GCS bucket)

---

## Cost Estimate

| Resource | Monthly Cost |
|----------|-------------|
| GXLB (forwarding rule) | ~$18 |
| Cloud CDN (egress) | ~$0.02-0.08/GB |
| Internet NEG | ~$0.01/hour |
| Cloud Armor (if added) | ~$5 + $0.75/million requests |
| **Total Base** | **~$25-50/month** |

---

## Next Steps

1. [ ] Create PR #1: GCP Foundation
2. [ ] Validate GCP project permissions
3. [ ] Confirm AWS NLB is acceptable (vs keeping ALB)
