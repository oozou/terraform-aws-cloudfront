data "aws_route53_zone" "hosted_zone" {
  name         = var.route53_domain_name
  private_zone = false
}

resource "aws_cloudfront_distribution" "distribution" {

  enabled = true

  dynamic "origin_group" {

    for_each = local.is_origin_group ? [true] : []

    content {
      origin_id = local.origin_group_id

      failover_criteria {
        status_codes = [403, 404, 500, 502]
      }

      member {
        origin_id = local.primary_origin_id
      }

      member {
        origin_id = var.secondary_origin_config.secondary_origin_id
      }
    }
  }

  origin {
    domain_name = var.origin_config.origin_domain_name
    origin_id   = local.primary_origin_id

    custom_header {
      name  = "custom-header-token"
      value = var.custom_header_token
    }

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "https-only"
      origin_read_timeout      = var.origin_read_timeout
      origin_ssl_protocols = [
        "TLSv1.2"
      ]
    }
  }

  dynamic "origin" {
    for_each = local.is_origin_group ? [true] : []

    content {
      domain_name = var.secondary_origin_config.secondary_domain_name
      origin_id   = var.secondary_origin_config.secondary_origin_id

      custom_header {
        name  = "custom-header-token"
        value = var.custom_header_token
      }

      custom_origin_config {
        http_port                = 80
        https_port               = 443
        origin_keepalive_timeout = 5
        origin_protocol_policy   = "https-only"
        origin_read_timeout      = var.origin_read_timeout
        origin_ssl_protocols = [
          "TLSv1.2"
        ]
      }
    }
  }

  ##s3 origin
  dynamic "origin" {
    for_each = local.enable_s3_origin ? [true] : []

    content {
      domain_name = var.s3_origin.origin_domain_name
      origin_id   = var.s3_origin.origin_id
    }
  }

  is_ipv6_enabled = var.is_ipv6_enabled

  default_root_object = var.default_root_object

  # By-default, fqdn for the CDN should be added, it should be the one for which certificate is issued
  aliases = concat([var.acm_cert_domain_name], var.domain_aliases)

  default_cache_behavior {
    # The parameter AllowedMethods cannot include POST, PUT, PATCH, or DELETE for a cached behavior associated with an origin group.
    allowed_methods  = var.allowed_methods
    cached_methods   = var.caching_config.cached_methods
    target_origin_id = local.is_origin_group ? local.origin_group_id : local.primary_origin_id

    forwarded_values {
      query_string = var.caching_config.forward_query_string

      cookies {
        forward           = var.caching_config.forward_cookies
        whitelisted_names = var.caching_config.forward_cookies_whitelisted_names
      }
      headers = var.caching_config.forwarded_headers
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.ttl_config.min_ttl
    default_ttl            = var.ttl_config.default_ttl
    max_ttl                = var.ttl_config.max_ttl
  }


  ## ordered_cache_behavior for s3 origin
  dynamic "ordered_cache_behavior" {
    for_each = local.enable_s3_origin ? [true] : []

    content {
      path_pattern     = var.s3_origin.path_pattern
      allowed_methods  = var.s3_origin.allowed_methods
      cached_methods   = var.s3_origin.cached_methods
      target_origin_id = var.s3_origin.origin_id #local.s3_origin_id

      forwarded_values {
        query_string = false
        headers      = ["Origin"]

        cookies {
          forward = "none"
        }
      }

      min_ttl                = 0
      default_ttl            = 86400
      max_ttl                = 31536000
      compress               = true
      viewer_protocol_policy = "allow-all"

      dynamic "lambda_function_association" {
        for_each = local.enable_lambda_function_association ? [true] : []

        content {
          event_type   = var.lambda_function_association.event_type
          lambda_arn   = var.lambda_function_association.lambda_arn
          include_body = var.lambda_function_association.include_body
        }
      }


    }
  }

  dynamic "custom_error_response" {
    for_each = ["400", "403", "404", "405", "414", "500", "501", "502", "503", "504"]
    content {
      error_code = custom_error_response.value
    }
  }

  price_class = var.price_class

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_config.geo_restriction_type
      locations        = var.geo_restriction_config.geo_restriction_locations
    }
  }

  tags = merge({
    Name = local.resource_name
  }, var.custom_tags)

  viewer_certificate {
    acm_certificate_arn            = var.cdn_certificate_arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2018"
    ssl_support_method             = "sni-only"
  }

  logging_config {
    include_cookies = var.log_include_cookies
    bucket          = "${var.log_aggregation_s3_bucket_name}.s3.amazonaws.com"
    prefix          = "${var.account_alias}/${local.resource_name}-cloudfront"
  }

  web_acl_id = var.is_enable_waf ? module.waf.web_acl_id : null

  # comment = "Managed by terraform" #<customer-prefix>-<env>-<paas>-cf
  comment = local.resource_name
}
