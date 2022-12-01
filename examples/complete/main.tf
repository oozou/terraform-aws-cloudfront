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

module "s3_cloudfront_log_bucket" {
  source  = "oozou/s3/aws"
  version = "1.1.3"

  prefix      = var.prefix
  environment = var.environment
  bucket_name = format("%s-cdn-log-bucket", var.name)

  centralize_hub     = false
  versioning_enabled = false
  force_s3_destroy   = false

  object_ownership              = "BucketOwnerPreferred"
  is_ignore_exist_object        = true
  is_enable_s3_hardening_policy = false

  additional_kms_key_policies = [data.aws_iam_policy_document.cloudfront_log_policy.json]

  tags = var.custom_tags
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

/* -------------------------------------------------------------------------- */
/*                                     VPC                                    */
/* -------------------------------------------------------------------------- */
module "vpc" {
  source       = "oozou/vpc/aws"
  version      = "1.2.4"
  prefix       = var.prefix
  environment  = var.environment
  account_mode = "spoke"

  cidr              = "172.17.171.0/24"
  public_subnets    = ["172.17.171.0/27", "172.17.171.32/27"]
  private_subnets   = ["172.17.171.128/26", "172.17.171.192/26"]
  database_subnets  = ["172.17.171.64/27", "172.17.171.96/27"]
  availability_zone = ["ap-southeast-1b", "ap-southeast-1c"]

  is_create_nat_gateway             = true
  is_enable_single_nat_gateway      = true
  is_enable_dns_hostnames           = true
  is_enable_dns_support             = true
  is_create_flow_log                = false
  is_enable_flow_log_s3_integration = false

  tags = var.custom_tags
}

/* -------------------------------------------------------------------------- */
/*                                     ECS                                    */
/* -------------------------------------------------------------------------- */
module "fargate_cluster" {
  source  = "oozou/ecs-fargate-cluster/aws"
  version = "1.0.6"

  # Generics
  prefix      = var.prefix
  environment = var.environment
  name        = var.name

  allow_access_from_principals = var.allow_access_from_principals

  # VPC Information
  vpc_id = var.networking_info["vpc_id"]

  # ALB
  is_public_alb     = true
  alb_listener_port = 443
  # alb_certificate_arn = var.certificate_arn["ap-southeast-1"]
  public_subnet_ids = module.vpc.public_subnet_ids # If is_public_alb is `true`, public_subnet_ids is required

  # ALB's DNS Record
  is_create_alb_dns_record = false # Default is `true`
  # route53_hosted_zone_name    = var.route53_hosted_zone_name        # The zone that alb record will be created
  # fully_qualified_domain_name = var.alb_fully_qualified_domain_name # ALB's record name

  tags = var.custom_tags
}

/* -------------------------------------------------------------------------- */
/*                               Fargate service                              */
/* -------------------------------------------------------------------------- */
module "nginx_service" {
  source  = "oozou/ecs-fargate-service/aws"
  version = "v1.1.9"

  # Generics
  prefix      = var.prefix
  environment = var.environment
  name        = format("%s-nginx-service", var.name)

  # ALB
  is_attach_service_with_lb = true
  alb_listener_arn          = module.fargate_cluster.alb_listener_http_arn
  # alb_host_header           = var.service_info["api"].service_alb_host_header
  # alb_paths                 = var.service_info["api"].alb_paths
  # alb_priority              = var.service_info["api"].alb_priority
  # custom_header_token       = var.custom_header_token # Default is `""`, specific for only allow header with given token
  ## Target group that listener will take action
  vpc_id = module.vpc.vpc_id
  health_check = {
    interval            = 20,
    path                = "",
    timeout             = 10,
    healthy_threshold   = 3,
    unhealthy_threshold = 3,
    matcher             = "200,201,204"
  }

  # Task definition
  service_info = {
    cpu_allocation = 256,
    mem_allocation = 512,
    port           = 80,
    image          = "nginx"
    mount_points   = []
  }

  # ECS service
  ecs_cluster_name            = module.fargate_cluster.ecs_cluster_name
  service_discovery_namespace = module.fargate_cluster.service_discovery_namespace
  service_count               = 1
  application_subnet_ids      = module.vpc.private_subnet_ids
  security_groups             = module.fargate_cluster.ecs_task_security_group_id
  # deployment_circuit_breaker  = var.deployment_circuit_breaker

  tags = var.custom_tags
}

/* -------------------------------------------------------------------------- */
/*                                 CloudFront                                 */
/* -------------------------------------------------------------------------- */
module "cloudfront_distribution" {
  source = "../../"

  prefix      = var.prefix
  name        = var.name
  environment = var.environment

  # By-default, fqdn for the CDN should be added, it should be the one for which certificate is issued
  is_automatic_create_dns_record = false
  domain_aliases = [
    # var.service_info["web"].service_alb_host_header,
    # var.service_info["api"].service_alb_host_header
  ]
  default_root_object = ""

  origin = {
    public_bucket = {
      domain_name              = "${module.s3_bucket.bucket_id}.s3.ap-southeast-1.amazonaws.com"
      origin_id                = module.s3_bucket.bucket_id
      origin_access_control_id = aws_cloudfront_origin_access_control.this.id
    }
    fargate_cluster_alb = {
      domain_name = module.fargate_cluster.alb_dns_name
      origin_id   = module.fargate_cluster.alb_dns_name
      custom_header = [{
        name  = "custom-header-token"
        value = var.custom_header_token
      }]
      custom_origin_config = {
        http_port                = 80
        https_port               = 443
        origin_keepalive_timeout = 5
        origin_protocol_policy   = "https-only"
        origin_read_timeout      = 60
        origin_ssl_protocols = [
          "TLSv1.2"
        ]
      }
    }
  }

  # Custom behavior
  ordered_cache_behaviors = [
    {
      path_pattern           = "/uploads/*"
      target_origin_id       = module.s3_bucket.bucket_id
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD", "OPTIONS"]
      cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
      compress               = true
      use_forwarded_values   = false
    },
    {
      path_pattern               = "/mobile/*",
      target_origin_id           = module.fargate_cluster.alb_dns_name,
      viewer_protocol_policy     = "redirect-to-https",
      allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"],
      compress                   = true,
      query_string               = true,
      query_string_cache_keys    = [],
      headers                    = ["Accept", "Accept-Language", "Authorization", "Host", "Origin", "Referer", "user-agent"],
      cookies_forward            = "all",
      min_ttl                    = 0,
      default_ttl                = 0,
      max_ttl                    = 0,
      response_headers_policy_id = null
    },
    {
      path_pattern               = "/_next/static/*",
      target_origin_id           = module.fargate_cluster.alb_dns_name,
      viewer_protocol_policy     = "redirect-to-https",
      allowed_methods            = ["GET", "HEAD", "OPTIONS"],
      compress                   = true,
      query_string               = true,
      query_string_cache_keys    = [],
      headers                    = ["Host"],
      cookies_forward            = "all",
      min_ttl                    = 0,
      default_ttl                = 86400,
      max_ttl                    = 31536000,
      response_headers_policy_id = null
    },
    {
      path_pattern               = "/images/*",
      target_origin_id           = module.s3_bucket.bucket_name,
      viewer_protocol_policy     = "redirect-to-https",
      allowed_methods            = ["GET", "HEAD", "OPTIONS"],
      compress                   = true,
      query_string               = true,
      query_string_cache_keys    = [],
      headers                    = ["Origin"],
      cookies_forward            = "all",
      min_ttl                    = 0,
      default_ttl                = 86400,
      max_ttl                    = 31536000,
      response_headers_policy_id = null
    },
    {
      path_pattern               = "/assets/*",
      target_origin_id           = module.fargate_cluster.alb_dns_name,
      viewer_protocol_policy     = "redirect-to-https",
      allowed_methods            = ["GET", "HEAD", "OPTIONS"],
      compress                   = true,
      query_string               = true,
      query_string_cache_keys    = [],
      headers                    = ["Accept", "Accept-Language", "Authorization", "Host", "Origin", "Referer", "user-agent"],
      cookies_forward            = "all",
      min_ttl                    = 0,
      default_ttl                = 86400,
      max_ttl                    = 31536000,
      response_headers_policy_id = null
    }
  ]
  # Default behavior
  default_cache_behavior = {
    target_origin_id          = module.fargate_cluster.alb_dns_name
    headers                   = ["Origin", "Authorization", "Referer", "Host", "Accept-Language", "Accept", "user-agent"]
    cookies_forward           = "all"
    cookies_whitelisted_names = []
    query_string              = true
    allowed_methods           = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods            = ["GET", "HEAD"]
    default_ttl               = 0
    min_ttl                   = 0
    max_ttl                   = 0
    compress                  = true
  }

  log_aggregation_s3_bucket_name = module.s3_cloudfront_log_bucket.bucket_name

  # DNS Mapping variables
  cdn_certificate_arn = null

  # Waf
  is_enable_waf                       = true
  is_enable_waf_default_rule          = false
  is_enable_waf_cloudwatch_metrics    = true
  is_enable_waf_sampled_requests      = true
  is_create_waf_logging_configuration = true
  waf_ip_sets_rule                    = var.waf_ip_sets_rule
  waf_ip_rate_based_rule              = var.waf_ip_rate_based_rule
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
