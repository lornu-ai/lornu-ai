# WAF Log Group (Regional)
resource "aws_cloudwatch_log_group" "waf" {
  name              = "/aws/wafv2/lornu-ai-production"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = {
    Name        = "lornu-ai-production-waf-logs"
    Environment = "production"
  }
}

# Regional WAF (For ALB in us-east-2)
resource "aws_wafv2_web_acl" "regional" {
  name        = "lornu-ai-production-waf-regional"
  description = "Regional WAFv2 Web ACL for Lornu AI ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "lornuAiProdWafRegional"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action { none {} }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    Environment = "production"
    GithubRepo  = var.github_repo
  }
}

# Global WAF (For CloudFront in us-east-1)
resource "aws_wafv2_web_acl" "cloudfront" {
  provider    = aws.us_east_1
  name        = "lornu-ai-production-waf-global"
  description = "Global WAFv2 Web ACL for Lornu AI CloudFront"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "lornuAiProdWafGlobal"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action { none {} }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 2
    override_action { none {} }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    Environment = "production"
    GithubRepo  = var.github_repo
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "regional" {
  resource_arn            = aws_wafv2_web_acl.regional.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
}
