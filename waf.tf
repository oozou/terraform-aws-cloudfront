module "waf" {
  #source  = "oozou/waf/aws"
  #version = "1.3.0"
  source = "git::ssh://git@github.com/oozou/terraform-aws-waf.git?ref=main"
  count = var.is_enable_waf ? 1 : 0

  name                   = var.name
  prefix                 = var.prefix
  scope                  = "CLOUDFRONT"
  environment            = var.environment
  ip_sets_rule           = var.waf_ip_sets_rule
  ip_rate_based_rule     = var.waf_ip_rate_based_rule
  is_enable_default_rule = var.is_enable_waf_default_rule

  ip_set               = var.waf_ip_set
  custom_rules         = var.waf_custom_rules
  custom_response_body = var.waf_custom_response_body

  managed_rules                    = var.waf_managed_rules
  default_action                   = var.waf_default_action
  is_enable_cloudwatch_metrics     = var.is_enable_waf_cloudwatch_metrics
  is_enable_sampled_requests       = var.is_enable_waf_sampled_requests
  is_create_logging_configuration  = var.is_create_waf_logging_configuration
  cloudwatch_log_retention_in_days = var.waf_cloudwatch_log_retention_in_days
  cloudwatch_log_kms_key_id        = var.waf_cloudwatch_log_kms_key_id
  redacted_fields                  = var.waf_redacted_fields
  logging_filter                   = var.waf_logging_filter

  tags = var.tags
}
