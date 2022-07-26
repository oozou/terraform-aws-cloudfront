module "cloudfront_distribution" {
  source = "../../"

  prefix      = var.prefix
  name        = "example"
  environment = var.environment

  log_aggregation_s3_bucket_name = module.s3_for_cloudfront_logs.bucket_name
  price_class                    = "PriceClass_100"
  custom_header_token            = ""

  # CDN variables
  origin_config = {
    origin_domain_name = "example.com"
    origin_id          = "example.com"
  }

  # By-default, fqdn for the CDN should be added, it should be the one for which certificate is issued
  domain_aliases      = ["example.example.com"]
  default_root_object = ""

  # Default behavior
  default_cache_behavior = {
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"
    use_forwarded_values     = false
    compress                 = false
    min_ttl                  = 0
    default_ttl              = 0
    max_ttl                  = 0
  }


  # DNS Mapping variables
  cdn_certificate_arn        = module.acm_virginia.certificate_arn[0]
  acm_cert_domain_name       = "example.example.com"
  route53_domain_name        = "example.com"
  is_enable_waf              = true
  is_enable_waf_default_rule = false
  waf_default_action         = "allow"
  tags                       = var.custom_tags
  providers = {
    aws = aws.virginia
   }
}
