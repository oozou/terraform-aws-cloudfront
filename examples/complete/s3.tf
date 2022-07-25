module "s3_for_cloudfront_logs" {
  source = "git@github.com:oozou/terraform-aws-s3.git?ref=v1.0.4"

  prefix      = var.prefix
  bucket_name = var.environment
  environment = var.environment

  centralize_hub     = false
  versioning_enabled = true
  force_s3_destroy   = true

  is_enable_s3_hardening_policy = false
  tags                          = var.custom_tags
}
