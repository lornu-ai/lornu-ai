# AWS Compute Strategy: Staging Environment

This document outlines the architectural transition and infrastructure provisioning required to establish an **AWS Staging Environment** for Lornu AI. This move supports a multi-cloud strategy, providing a failover and testing ground for the core FastAPI/ADK Agent logic currently residing in GCP and Cloudflare.

---

### 1. Compute Strategy Decision Matrix
Based on the objective to de-risk Cloudflare Workers while maintaining the performance of the **FastAPI/ADK Agent** backend, the following evaluation is set:

| Feature | AWS Lambda | AWS ECS (Fargate) | AWS EKS |
| :--- | :--- | :--- | :--- |
| **Complexity** | Low | Medium | High |
| **Agent Suitability** | Poor (Timeout/Cold Starts) | **Excellent (Long-lived)** | Overkill for Staging |
| **Cost** | Pay-per-request | Balanced (Serverless) | High (Control Plane) |
| **Scaling** | Instant (but limited) | Rapid (Horizontal) | Highly Granular |

**Recommendation**: **AWS ECS (Fargate)**.
*   **Reasoning**: ECS Fargate provides a serverless container experience that mirrors our GCP Cloud Run setup. It natively supports long-lived connections required for streaming LLM responses (Gemini) and the ADK Agent's `process()` execution cycles, which often exceed Lambda’s optimal duration.
