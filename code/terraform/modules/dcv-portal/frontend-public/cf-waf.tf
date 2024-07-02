# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# WAF
resource "aws_wafv2_ip_set" "wafv2_ip_set" {
  count     = (var.module_network.config.ip_allow_list_enabled == true ? 1 : 0)
  provider  = aws.us-east-1
  name      = "${var.env.prefix}-frontend-ip-allow-list"
  scope     = "CLOUDFRONT"
  addresses = var.module_network.config.ip_allow_list
  ip_address_version = "IPV4"
}

resource "aws_wafv2_web_acl" "wafv2_web_acl" {
  count     = (var.module_network.config.ip_allow_list_enabled == true ? 1 : 0)
  provider  = aws.us-east-1
  name      = "${var.env.prefix}-frontend-ip-allow-list"
  scope     = "CLOUDFRONT"
  default_action {
    block {}
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.env.prefix}-frontend-ip-allow-list"
    sampled_requests_enabled   = true
  }
  rule {
    name     = "${var.env.prefix}-frontend-ip-allow-list"
    priority = 1
    action {
      allow {}
    }
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.wafv2_ip_set[0].arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowedIP"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

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
      cloudwatch_metrics_enabled = false
      metric_name                = "BadInputs"
      sampled_requests_enabled   = false
    }
  }
}
