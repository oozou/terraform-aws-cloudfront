locals {
  origin_group_id                    = "origin_group_${var.prefix}_${var.environment}_${var.name}}"
  primary_origin_id                  = var.origin_config.origin_id
  is_origin_group                    = var.secondary_origin_config != null ? true : false
  enable_s3_origin                   = var.s3_origin != null ? true : false
  enable_lambda_function_association = var.lambda_function_association != null ? true : false
  resource_name                      = "${var.prefix}-${var.environment}-${var.name}-cf"
  aliases_records                    = { for name in var.domain_aliases : name => { "name" = name } }
  is_use_cloudfront_cert_viewer      = var.cdn_certificate_arn == null && var.is_automatic_create_dns_record == false && length(var.domain_aliases) == 0 ? true : false

  tags = merge(
    {
      "Environment" = var.environment,
      "Terraform"   = "true"
    },
    var.tags
  )
}
