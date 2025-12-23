# AWS Compute Strategy: Staging Environment

> **📖 For complete architectural details, see [AWS_STAGING_DESIGN.md](./AWS_STAGING_DESIGN.md)**

This document provides a quick reference for the compute strategy decision for the AWS Staging Environment. This move supports a multi-cloud strategy, providing a failover and testing ground for the core FastAPI/ADK Agent logic currently residing in GCP and Cloudflare.

---

## Quick Summary

**Decision**: **AWS ECS (Fargate)** has been selected as the compute platform for the staging environment.

---

## 1. Compute Strategy Decision Matrix

Based on the objective to de-risk Cloudflare Workers while maintaining the performance of the **FastAPI/ADK Agent** backend, the following evaluation was conducted:

| Feature | AWS Lambda | AWS ECS (Fargate) | AWS EKS |
| :--- | :--- | :--- | :--- |
| **Complexity** | Low | Medium | High |
| **Agent Suitability** | Poor (Timeout/Cold Starts) | **Excellent (Long-lived)** | Overkill for Staging |
| **Cost** | Pay-per-request | Balanced (Serverless) | High (Control Plane) |
| **Scaling** | Instant (but limited) | Rapid (Horizontal) | Highly Granular |

**Recommendation**: **AWS ECS (Fargate)** ✅

### Reasoning

ECS Fargate provides a serverless container experience that mirrors our GCP Cloud Run setup. It natively supports long-lived connections required for:
- Streaming LLM responses (Gemini)
- ADK Agent's `process()` execution cycles, which often exceed Lambda's optimal duration
- WebSocket connections for real-time communication

---

## 2. Implementation Status

- ✅ **Terraform Infrastructure**: Provisioned in `terraform/aws/staging/`
- ✅ **CI/CD Workflow**: Automated via `.github/workflows/terraform-aws.yml`
- ✅ **Containerization**: Multi-stage Dockerfile with Bun + Python
- ✅ **Networking**: VPC, subnets, NAT Gateway configured
- ✅ **Load Balancing**: Application Load Balancer with health checks
- ✅ **Security**: IAM roles, security groups, Secrets Manager integration

---

## 3. Related Documentation

- **[AWS_STAGING_DESIGN.md](./AWS_STAGING_DESIGN.md)**: Complete architectural design and implementation details
- **[Dockerfile](../../Dockerfile)**: Containerization strategy
- **[terraform/aws/staging/](../../terraform/aws/staging/)**: Infrastructure as Code
