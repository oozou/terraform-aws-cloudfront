module "waf" {
  count                  = var.is_enable_waf ? 1 : 0
  source                 = "git@github.com:oozou/terraform-aws-waf.git?ref=develop"
  name                   = var.name
  prefix                 = var.prefix
  scope                  = "CLOUDFRONT"
  environment            = var.environment
  ip_sets_rule           = var.waf_ip_sets_rule
  ip_rate_based_rule     = var.waf_ip_rate_based_rule
  is_enable_default_rule = var.is_enable_waf_default_rule

  managed_rules                   = var.waf_managed_rules
  default_action                  = var.waf_default_action
  is_enable_cloudwatch_metrics    = var.is_enable_waf_cloudwatch_metrics
  is_enable_sampled_requests      = var.is_enable_waf_sampled_requests
  is_create_logging_configuration = var.is_create_waf_logging_configuration
  redacted_fields                 = var.waf_redacted_fields
  logging_filter                  = var.waf_logging_filter

  tags = var.custom_tags
}
