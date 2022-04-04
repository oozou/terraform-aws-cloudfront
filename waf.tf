module "waf_cf" {
  count                           = local.enable_waf
  source                          = "git@github.com:oozou/terraform-aws-waf.git?ref=develop"
  name                            = var.name
  prefix                          = var.prefix
  scope                           = "CLOUDFRONT"
  environment                     = var.environment
  ip_sets_rule                    = var.waf_ip_sets_rule
  ip_rate_based_rule              = var.waf_ip_rate_based_rule
  is_enable_default_rule          = var.is_enable_waf_default_rule
  is_enable_sampled_requests      = true
  is_enable_cloudwatch_metrics    = true
  is_create_logging_configuration = true
  tags                            = var.custom_tags
  #   providers = {
  #     aws = aws.virginia
  #   }
}
