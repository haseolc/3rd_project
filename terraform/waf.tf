resource "aws_wafv2_web_acl" "smoke" {
  name        = "3rd-project-smoke-waf"
  description = "Regional WAF protecting the 3rd project smoke test ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 30

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimitPerIp"
    priority = 40

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 100
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitPerIp"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "3rdProjectSmokeWaf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "3rd-project-smoke-waf"
    purpose     = "web-application-protection"
    environment = "sandbox"
    created-by  = "terraform"
  }
}

resource "aws_wafv2_web_acl_association" "smoke" {
  resource_arn = aws_lb.smoke.arn
  web_acl_arn  = aws_wafv2_web_acl.smoke.arn
}

resource "aws_cloudwatch_log_group" "waf" {
  #checkov:skip=CKV_AWS_158:CloudWatch Logs default encryption is used for this temporary sandbox log group; sensitive Authorization and Cookie headers are redacted.
  #checkov:skip=CKV_AWS_338:Thirty-day retention is intentional for ephemeral sandbox WAF request logs to limit storage cost.
  name              = "aws-waf-logs-3rd-project-smoke"
  retention_in_days = 30

  tags = {
    Name        = "aws-waf-logs-3rd-project-smoke"
    purpose     = "waf-request-audit"
    environment = "sandbox"
    created-by  = "terraform"
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "smoke" {
  resource_arn = aws_wafv2_web_acl.smoke.arn

  log_destination_configs = [
    aws_cloudwatch_log_group.waf.arn,
  ]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
}
