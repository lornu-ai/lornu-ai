# DNS infrastructure has been consolidated into cdn.tf
#
# ARCHITECTURE CHANGE: Transition to CloudFront-only
# ==================
# Previously, this file managed:
#   - Route53 zone for apex domain (lornu.ai)
#   - ACM certificate for ALB SSL/TLS termination
#   - Route53 validation records (1h15m timeout delay)
#   - DNS pointing to ALB listener
#
# Now all DNS is managed by cdn.tf:
#   - Route53 zone and records (both apex and api subdomains)
#   - CloudFront distribution with aliases for both domains
#   - Single ACM certificate for CloudFront
#   - Direct DNS aliases to CloudFront (no validation delays)
#
# Benefits:
#   - Eliminates 1h15m ACM certificate validation timeout
#   - Simpler architecture: CloudFront → EKS directly (no ALB)
#   - SSL/TLS termination at edge with CloudFront
#   - Reduced operational overhead
#
# This file is maintained for reference and can be removed in future refactoring.
