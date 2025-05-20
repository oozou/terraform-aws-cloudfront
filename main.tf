/* -------------------------------------------------------------------------- */
/*                                   Locals                                   */
/* -------------------------------------------------------------------------- */
locals {
  name                          = var.name_override == "" ? format("%s-%s-%s-cf", var.prefix, var.environment, var.name) : var.name_override
  aliases_records               = { for name in var.domain_aliases : name => { "name" = name } }
  is_use_cloudfront_cert_viewer = var.cdn_certificate_arn == null && var.is_automatic_create_dns_record == false && length(var.domain_aliases) == 0 ? true : false

  tags = merge(
    {
      "Environment" = var.environment,
      "Terraform"   = "true"
      "Module"      = "terraform-aws-cloudfront"
    },
    var.tags
  )
}

locals {
  empty_prefix      = var.prefix == "" ? true : false
  empty_environment = var.environment == "" ? true : false
  empty_name        = var.name == "" ? true : false
  raise_empty_name  = local.name == "" && (local.empty_prefix || local.empty_environment || local.empty_name) ? file("`var.name_override` or (`var.prefix`, `var.environment` and `var.name is required`) ") : null
}

/* -------------------------------------------------------------------------- */
/*                                   Route53                                  */
/* -------------------------------------------------------------------------- */
data "aws_route53_zone" "hosted_zone" {
  count = var.is_automatic_create_dns_record ? 1 : 0

  name         = var.route53_domain_name
  private_zone = false
}

resource "aws_route53_record" "application" {
  for_each = var.is_automatic_create_dns_record ? local.aliases_records : {}
  zone_id  = data.aws_route53_zone.hosted_zone[0].id
  name     = each.value.name
  type     = "A"

  alias {
    name                   = lower(aws_cloudfront_distribution.distribution.domain_name)
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

/* -------------------------------------------------------------------------- */
/*                    Origin Access Control Indentity (OAI)                   */
/* -------------------------------------------------------------------------- */
resource "aws_cloudfront_origin_access_identity" "this" {
  for_each = var.origin_access_identities

  comment = each.value

  lifecycle {
    create_before_destroy = true
  }
}

/* -------------------------------------------------------------------------- */
/*                                Distribution                                */
/* -------------------------------------------------------------------------- */
resource "aws_cloudfront_distribution" "distribution" {
  enabled             = var.is_enable_distribution
  comment             = local.name
  price_class         = var.price_class
  web_acl_id          = var.is_enable_waf ? module.waf[0].web_acl_id : null
  is_ipv6_enabled     = var.is_ipv6_enabled
  default_root_object = var.default_root_object
  retain_on_delete    = var.retain_on_delete
  staging             = var.is_staging

  # By-default, fqdn for the CDN should be added, it should be the one for which certificate is issued
  aliases = var.domain_aliases

  dynamic "origin_group" {
    for_each = var.origin_group
    iterator = origin_group

    content {
      origin_id = lookup(origin_group.value, "origin_id", origin_group.key)

      failover_criteria {
        status_codes = origin_group.value["failover_status_codes"]
      }

      member {
        origin_id = origin_group.value["primary_member_origin_id"]
      }

      member {
        origin_id = origin_group.value["secondary_member_origin_id"]
      }
    }
  }

  default_cache_behavior {
    allowed_methods  = lookup(var.default_cache_behavior, "allowed_methods", ["GET", "HEAD", "OPTIONS"])
    cached_methods   = lookup(var.default_cache_behavior, "cached_methods", ["GET", "HEAD"])
    target_origin_id = var.default_cache_behavior.target_origin_id

    compress    = lookup(var.default_cache_behavior, "compress", null)
    min_ttl     = lookup(var.default_cache_behavior, "min_ttl", null)
    default_ttl = lookup(var.default_cache_behavior, "default_ttl", null)
    max_ttl     = lookup(var.default_cache_behavior, "max_ttl", null)

    viewer_protocol_policy    = lookup(var.default_cache_behavior, "viewer_protocol_policy", "redirect-to-https")
    field_level_encryption_id = lookup(var.default_cache_behavior, "field_level_encryption_id", null)
    smooth_streaming          = lookup(var.default_cache_behavior, "smooth_streaming", null)
    trusted_signers           = lookup(var.default_cache_behavior, "trusted_signers", null)
    trusted_key_groups        = lookup(var.default_cache_behavior, "trusted_key_groups", null)

    cache_policy_id            = lookup(var.default_cache_behavior, "cache_policy_id", null)
    origin_request_policy_id   = lookup(var.default_cache_behavior, "origin_request_policy_id", null)
    response_headers_policy_id = lookup(var.default_cache_behavior, "response_headers_policy_id", null)
    realtime_log_config_arn    = lookup(var.default_cache_behavior, "realtime_log_config_arn", null)

    dynamic "forwarded_values" {
      for_each = lookup(var.default_cache_behavior, "use_forwarded_values", true) ? [true] : []

      content {
        query_string            = lookup(var.default_cache_behavior, "query_string", false)
        query_string_cache_keys = lookup(var.default_cache_behavior, "query_string_cache_keys", [])
        headers                 = lookup(var.default_cache_behavior, "headers", [])

        cookies {
          forward           = lookup(var.default_cache_behavior, "cookies_forward", "none")
          whitelisted_names = lookup(var.default_cache_behavior, "cookies_whitelisted_names", null)
        }
      }
    }

    dynamic "lambda_function_association" {
      for_each = lookup(var.default_cache_behavior, "lambda_function_association", [])
      iterator = lambda_function

      content {
        event_type   = lambda_function.value.event_type
        lambda_arn   = lambda_function.value.lambda_arn
        include_body = lookup(lambda_function.value, "include_body", null)
      }
    }

    dynamic "function_association" {
      for_each = lookup(var.default_cache_behavior, "function_association", [])
      iterator = function

      content {
        event_type   = function.value.event_type
        function_arn = function.value.function_arn
      }
    }
  }

  dynamic "origin" {
    for_each = var.origin

    content {
      domain_name              = origin.value.domain_name
      origin_id                = lookup(origin.value, "origin_id", origin.key)
      origin_path              = lookup(origin.value, "origin_path", "")
      connection_attempts      = lookup(origin.value, "connection_attempts", null)
      connection_timeout       = lookup(origin.value, "connection_timeout", null)
      origin_access_control_id = lookup(origin.value, "origin_access_control_id", null)

      dynamic "s3_origin_config" {
        for_each = length(keys(lookup(origin.value, "s3_origin_config", {}))) == 0 ? [] : [lookup(origin.value, "s3_origin_config", {})]

        content {
          origin_access_identity = lookup(s3_origin_config.value, "cloudfront_access_identity_path",
            lookup(
              lookup(
                aws_cloudfront_origin_access_identity.this,
                lookup(s3_origin_config.value, "origin_access_identity", ""),
                {}
              ),
              "cloudfront_access_identity_path",
              null
            )
          )
        }
      }

      dynamic "custom_origin_config" {
        for_each = length(lookup(origin.value, "custom_origin_config", "")) == 0 ? [] : [lookup(origin.value, "custom_origin_config", "")]

        content {
          http_port                = custom_origin_config.value.http_port
          https_port               = custom_origin_config.value.https_port
          origin_protocol_policy   = custom_origin_config.value.origin_protocol_policy
          origin_ssl_protocols     = custom_origin_config.value.origin_ssl_protocols
          origin_keepalive_timeout = lookup(custom_origin_config.value, "origin_keepalive_timeout", null)
          origin_read_timeout      = lookup(custom_origin_config.value, "origin_read_timeout", null)
        }
      }

      dynamic "custom_header" {
        for_each = lookup(origin.value, "custom_header", [])

        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }

      dynamic "origin_shield" {
        for_each = length(keys(lookup(origin.value, "origin_shield", {}))) == 0 ? [] : [lookup(origin.value, "origin_shield", {})]

        content {
          enabled              = origin_shield.value.enabled
          origin_shield_region = origin_shield.value.origin_shield_region
        }
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    iterator = cache_behavior

    content {
      path_pattern           = cache_behavior.value["path_pattern"]
      target_origin_id       = cache_behavior.value["target_origin_id"]
      viewer_protocol_policy = cache_behavior.value["viewer_protocol_policy"]

      allowed_methods           = lookup(cache_behavior.value, "allowed_methods", ["GET", "HEAD", "OPTIONS"])
      cached_methods            = lookup(cache_behavior.value, "cached_methods", ["GET", "HEAD"])
      compress                  = lookup(cache_behavior.value, "compress", null)
      field_level_encryption_id = lookup(cache_behavior.value, "field_level_encryption_id", null)
      smooth_streaming          = lookup(cache_behavior.value, "smooth_streaming", null)
      trusted_signers           = lookup(cache_behavior.value, "trusted_signers", null)
      trusted_key_groups        = lookup(cache_behavior.value, "trusted_key_groups", null)

      cache_policy_id            = lookup(cache_behavior.value, "cache_policy_id", null)
      origin_request_policy_id   = lookup(cache_behavior.value, "origin_request_policy_id", null)
      response_headers_policy_id = lookup(cache_behavior.value, "response_headers_policy_id", null)
      realtime_log_config_arn    = lookup(cache_behavior.value, "realtime_log_config_arn", null)

      min_ttl     = lookup(cache_behavior.value, "min_ttl", null)
      default_ttl = lookup(cache_behavior.value, "default_ttl", null)
      max_ttl     = lookup(cache_behavior.value, "max_ttl", null)

      dynamic "forwarded_values" {
        for_each = lookup(cache_behavior.value, "use_forwarded_values", true) ? [true] : []

        content {
          query_string            = lookup(cache_behavior.value, "query_string", false)
          query_string_cache_keys = lookup(cache_behavior.value, "query_string_cache_keys", [])
          headers                 = lookup(cache_behavior.value, "headers", [])

          cookies {
            forward           = lookup(cache_behavior.value, "cookies_forward", "none")
            whitelisted_names = lookup(cache_behavior.value, "cookies_whitelisted_names", null)
          }
        }
      }

      dynamic "lambda_function_association" {
        for_each = lookup(cache_behavior.value, "lambda_function_association", [])
        iterator = lambda_function

        content {
          event_type   = lambda_function.value.event_type
          lambda_arn   = lambda_function.value.lambda_arn
          include_body = lookup(lambda_function.value, "include_body", null)
        }
      }

      dynamic "function_association" {
        for_each = lookup(cache_behavior.value, "function_association", [])
        iterator = function

        content {
          event_type   = function.value.event_type
          function_arn = function.value.function_arn
        }
      }
    }
  }

  dynamic "custom_error_response" {
    for_each = length(flatten([var.custom_error_response])[0]) > 0 ? flatten([var.custom_error_response]) : []

    content {
      error_code = custom_error_response.value["error_code"]

      response_code         = lookup(custom_error_response.value, "response_code", null)
      response_page_path    = lookup(custom_error_response.value, "response_page_path", null)
      error_caching_min_ttl = lookup(custom_error_response.value, "error_caching_min_ttl", null)
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_config.geo_restriction_type
      locations        = var.geo_restriction_config.geo_restriction_locations
    }
  }

  viewer_certificate {
    acm_certificate_arn            = local.is_use_cloudfront_cert_viewer ? null : var.cdn_certificate_arn
    cloudfront_default_certificate = local.is_use_cloudfront_cert_viewer ? true : false
    minimum_protocol_version       = local.is_use_cloudfront_cert_viewer ? "TLSv1" : "TLSv1.2_2018"
    ssl_support_method             = local.is_use_cloudfront_cert_viewer ? null : "sni-only"
  }

  logging_config {
    include_cookies = var.log_include_cookies
    bucket          = "${var.log_aggregation_s3_bucket_name}.s3.amazonaws.com"
    prefix          = "${var.environment}/${local.name}-cloudfront"
  }

  continuous_deployment_policy_id = var.is_create_continuous_deployment_policy ? aws_cloudfront_continuous_deployment_policy.main[0].id : null

  tags = merge(local.tags, { "Name" : local.name })
}

/* -------------------------------------------------------------------------- */
/*                                     IAM                                    */
/* -------------------------------------------------------------------------- */
resource "aws_iam_role" "main" {
  count = var.is_create_log_access_role ? 1 : 0

  name = "${local.name}-cloudfront-logs-access-role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "*"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(local.tags, { "Name" : local.name })
}

resource "aws_iam_role_policy" "main" {
  count = var.is_create_log_access_role ? 1 : 0

  name = "${local.name}-cloudfront-logs-access-policy"
  role = aws_iam_role.main[0].id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
         "s3:GetBucketAcl",
         "s3:PutBucketAcl"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.log_aggregation_s3_bucket_name}"
    }
  ]
}
EOF

}

resource "aws_cloudfront_continuous_deployment_policy" "main" {
  enabled = var.is_create_continuous_deployment_policy

  staging_distribution_dns_names {
    items    = [var.staging_domain_name]
    quantity = 1
  }

  dynamic "traffic_config" {
    for_each = var.traffic_config.type != "" ? [1] : []

    content {
      type = var.traffic_config.type

      dynamic "single_header_config" {
        for_each = var.traffic_config.type == "SingleHeader" ? [1] : []
        content {
          header = var.traffic_config.single_header_config.header
          value  = var.traffic_config.single_header_config.value
        }
      }

      dynamic "session_stickiness_config" {
        for_each = contains(keys(var.traffic_config.single_weight_config), "session_stickiness_config") && var.traffic_config.single_weight_config.session_stickiness_config != null ? [1] : []
        content {
          idle_ttl    = var.traffic_config.single_weight_config.session_stickiness_config.idle_ttl
          maximum_ttl = var.traffic_config.single_weight_config.session_stickiness_config.maximum_ttl
        }
      }
    }
  }

}
