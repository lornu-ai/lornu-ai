# Plan A — Product Mission

## Goal
**Deliver a 50–70% reduction in development time and operational overhead.**

## Why Plan A
Plan A is the Minimum Viable Infrastructure (MVI) strategy for Lornu AI. It consolidates delivery onto a **single EKS cluster** and isolates environments by namespace, enabling faster iteration without sacrificing governance.

## Target Outcomes
- Reduce infra complexity and OpEx.
- Standardize deployment workflows across environments.
- Make AI-assisted development deterministic and safe.

## Core Features (MVI)
1. **Single-cluster architecture** with `lornu-dev`, `lornu-staging`, `lornu-prod` namespaces.
2. **Kustomize-based overlays** for environment-specific configuration.
3. **Unified tooling**: Bun for frontend, uv for backend, Terraform Cloud for infra.
