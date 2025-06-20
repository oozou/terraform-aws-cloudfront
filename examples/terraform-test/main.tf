data "aws_caller_identity" "this" {}

/* -------------------------------------------------------------------------- */
/*                                     S3                                     */
/* -------------------------------------------------------------------------- */
data "aws_iam_policy_document" "cloudfront_log_policy" {
  statement {
    sid    = "Allow CloudFront to use the key to deliver logs"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }
}

# Create S3 bucket for CloudFront logs manually to ensure ACL compatibility
resource "aws_s3_bucket" "cloudfront_log_bucket" {
  bucket        = format("%s-%s-%s-%s-cdn-log-bucket", var.prefix, var.environment, var.name, data.aws_caller_identity.this.account_id)
  force_destroy = true

  tags = merge(var.custom_tags, {
    Name = format("%s-%s-%s-cdn-log-bucket", var.prefix, var.environment, var.name)
  })
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_log_bucket" {
  bucket = aws_s3_bucket.cloudfront_log_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudfront_log_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_log_bucket]
  bucket     = aws_s3_bucket.cloudfront_log_bucket.id
  acl        = "private"
}

resource "aws_s3_bucket_public_access_block" "cloudfront_log_bucket" {
  bucket = aws_s3_bucket.cloudfront_log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "oac_access_kms_policy" {
  statement {
    sid    = "Allow CloudFront to use the key to deliver logs"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*",
    ]
    resources = ["*"]
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"

      values = [
        module.cloudfront_distribution.cloudfront_distribution_arn
      ]
    }
  }
}

data "aws_iam_policy_document" "cloudfront_get_public_object_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = ["${module.s3_bucket.bucket_arn}/*"]
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"

      values = [
        module.cloudfront_distribution.cloudfront_distribution_arn
      ]
    }
  }
}

module "s3_bucket" {
  source  = "oozou/s3/aws"
  version = "1.1.3"

  prefix      = var.prefix
  environment = var.environment
  bucket_name = format("%s-bucket", var.name)

  versioning_enabled = true
  force_s3_destroy   = true
  folder_names       = ["uploads", "images"]

  additional_kms_key_policies = [data.aws_iam_policy_document.oac_access_kms_policy.json]
  additional_bucket_polices   = [data.aws_iam_policy_document.cloudfront_get_public_object_policy.json]

  tags = var.custom_tags
}

resource "aws_s3_object" "default_object" {
  key        = "test-file.txt"
  bucket     = module.s3_bucket.bucket_id
  source     = "test-file.txt"
  kms_key_id = module.s3_bucket.bucket_kms_key_arn
}

/* -------------------------------------------------------------------------- */
/*                                 CloudFront                                 */
/* -------------------------------------------------------------------------- */
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = format("%s-%s-%s-oac", var.prefix, var.environment, var.name)
  description                       = "OAC for S3 access with encryption"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

module "cloudfront_distribution" {
  source = "../../"

  prefix      = var.prefix
  name        = var.name
  environment = var.environment

  # By-default, fqdn for the CDN should be added, it should be the one for which certificate is issued
  is_automatic_create_dns_record = false
  domain_aliases = [
    # "api.oozou.com"
  ]
  default_root_object = ""

  origin = {
    public_bucket = {
      domain_name              = "${module.s3_bucket.bucket_id}.s3.ap-southeast-1.amazonaws.com"
      origin_id                = module.s3_bucket.bucket_id
      origin_access_control_id = aws_cloudfront_origin_access_control.this.id
    }
  }

  # Custom behavior
  ordered_cache_behaviors = [
    {
      path_pattern           = "/*"
      target_origin_id       = module.s3_bucket.bucket_id
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD", "OPTIONS"]
      cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
      compress               = true
      use_forwarded_values   = false
    }
  ]
  # Default behavior
  default_cache_behavior = {
    path_pattern           = "/*"
    target_origin_id       = module.s3_bucket.bucket_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
    compress               = true
    use_forwarded_values   = false
  }

  log_aggregation_s3_bucket_name = aws_s3_bucket.cloudfront_log_bucket.id

  # DNS Mapping variables
  cdn_certificate_arn = null

  # Custom error response
  custom_error_response = [{
    error_code         = 404
    response_code      = 404
    response_page_path = "/errors/404.html"
    }, {
    error_code         = 403
    response_code      = 403
    response_page_path = "/errors/403.html"
  }]

  # Waf
  is_enable_waf                       = true
  is_enable_waf_default_rule          = false
  is_enable_waf_cloudwatch_metrics    = true
  is_enable_waf_sampled_requests      = true
  is_create_waf_logging_configuration = true
  waf_ip_sets_rule                    = []
  waf_ip_rate_based_rule              = null
  waf_managed_rules = [
    {
      name            = "AWSManagedRulesCommonRuleSet",
      priority        = 10
      override_action = "none"
      excluded_rules  = ["SizeRestrictions_BODY", "CrossSiteScripting_BODY"]
    },
    {
      name            = "AWSManagedRulesAmazonIpReputationList",
      priority        = 20
      override_action = "none"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesKnownBadInputsRuleSet",
      priority        = 30
      override_action = "none"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesSQLiRuleSet",
      priority        = 40
      override_action = "none"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesLinuxRuleSet",
      priority        = 50
      override_action = "none"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesUnixRuleSet",
      priority        = 60
      override_action = "none"
      excluded_rules  = []
    }
  ]
  waf_default_action  = "allow"
  waf_redacted_fields = []
  waf_logging_filter  = {}

  providers = {
    aws = aws.virginia
  }

  tags = var.custom_tags
}
