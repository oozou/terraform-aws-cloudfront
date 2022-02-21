locals {
  origin_group_id   = "origin_group_${var.base_name}"
  primary_origin_id = var.origin_config.origin_id
  is_origin_group   = var.secondary_origin_config != null ? true : false
  enable_s3_origin  = var.s3_origin != null ? true: false
  enable_lambda_function_association = var.lambda_function_association != null ? true : false
}

data "aws_route53_zone" "hosted_zone" {
  name         = var.route53_domain_name
  private_zone = false
}
