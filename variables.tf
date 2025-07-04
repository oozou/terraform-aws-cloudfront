variable "name_override" {
  description = "(Optional) Full name to override usage from format(\"%s-%s-%s-cf\", var.prefix, var.environment, var.name)"
  type        = string
  default     = ""
}

variable "prefix" {
  description = "(Optional) Prefix as a part of format(\"%s-%s-%s-cf\", var.prefix, var.environment, var.name); ex. oozou-xxx-xxx-cf"
  type        = string
  default     = ""
}

variable "environment" {
  description = "(Optional) Environment as a part of format(\"%s-%s-%s-cf\", var.prefix, var.environment, var.name); ex. xxx-prod-xxx-cf"
  type        = string
  default     = ""
}

variable "name" {
  description = "(Optional) Name as a part of format(\"%s-%s-%s-cf\", var.prefix, var.environment, var.name); ex. xxx-xxx-cms-cf"
  type        = string
  default     = ""
}

variable "log_aggregation_s3_bucket_name" {
  description = "[Required] S3 bucket name where logs are stored for cloudfront"
  type        = string
}

variable "domain_aliases" {
  description = "CNAMEs (domain names) for the distribution"
  type        = list(string)
  default     = []
}

variable "price_class" {
  description = "Price class for this distribution: `PriceClass_All`, `PriceClass_200`, `PriceClass_100` (price class denotes the edge locations which are supported by CDN)"
  type        = string
  default     = "PriceClass_100" # By-default supporting edge locations only in USA and Europe
}

variable "tags" {
  description = "Custom tags which can be passed on to the AWS resources. They should be key value pairs having distinct keys."
  type        = map(string)
  default     = {}
}

variable "default_cache_behavior" {
  description = "Specify CloudFront configuration related to caching behavior"
  type        = any
  default = {
    allowed_methods           = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods            = ["GET", "HEAD"]
    headers                   = ["Host"]
    cookies_forward           = "none"
    cookies_whitelisted_names = []
    query_string              = false
    query_string_cache_keys   = []
    compress                  = true
    min_ttl                   = 0
    default_ttl               = 3600
    max_ttl                   = 86400
  }

}

variable "geo_restriction_config" {
  description = "Specify configuration for restriction based on location"
  type = object({
    geo_restriction_type      = string       # Method that use to restrict distribution of your content by country: `none`, `whitelist`, or `blacklist
    geo_restriction_locations = list(string) # List of country codes for which CloudFront either to distribute content (whitelist) or not distribute your content (blacklist)
  })
  default = {
    geo_restriction_type      = "none"
    geo_restriction_locations = [] # e.g. ["US", "CA", "GB", "DE"]
  }
}



variable "is_enable_distribution" {
  description = "enable or disable distribution"
  type        = bool
  default     = true
}

variable "retain_on_delete" {
  description = "retain cloudfront when destroy"
  type        = bool
  default     = true
}

variable "is_ipv6_enabled" {
  description = "State of CloudFront IPv6"
  type        = bool
  default     = true
}

variable "log_include_cookies" {
  description = "Include cookies in access logs"
  type        = bool
  default     = false
}

#  ACM variables
# domain name for the created CDN
variable "is_automatic_create_dns_record" {
  description = "Whether to automatically create cloudfront A record."
  type        = bool
  default     = true
}

# name of the hosted zone for the route 53 record for CDN
variable "route53_domain_name" {
  description = "[Required] The Name of the already existing Route53 Hosted Zone (i.e.: 'spike.abc.cloud')"
  type        = string
  default     = null
}

variable "cdn_certificate_arn" {
  description = "Specify ARN for CDN certificate"
  type        = string
  default     = null
}

variable "default_root_object" {
  description = "File name for default root object"
  type        = string
  default     = "index.html"
}

variable "origin_group" {
  description = "One or more origin_group for this distribution (multiples allowed)."
  type        = any
  default     = {}
}

variable "origin" {
  description = "One or more origins for this distribution (multiples allowed)."
  type        = any
  default     = {}
}

variable "ordered_cache_behaviors" {
  description = "An ordered list of cache behaviors resource for this distribution. List from top to bottom in order of precedence. The topmost cache behavior will have precedence 0."
  type        = any
  default     = []
}

variable "origin_access_identities" {
  description = "Map of CloudFront origin access identities (value as a comment)"
  type        = map(string)
  default     = {}
}

variable "custom_error_response" {
  description = "One or more custom error response elements"
  type        = any
  default     = {}
}

/* -------------------------------------------------------------------------- */
/*                                     IAM                                    */
/* -------------------------------------------------------------------------- */
variable "is_create_log_access_role" {
  description = "Whether to create log access role or not; just make role no relate resource in this module used"
  type        = bool
  default     = true
}

/* -------------------------------------------------------------------------- */
/*                                     WAF                                    */
/* -------------------------------------------------------------------------- */
variable "is_enable_waf" {
  type        = bool
  description = "Whether to enable WAF for CloudFront"
  default     = false
}

variable "is_enable_waf_default_rule" {
  type        = bool
  description = "If true with enable default rule (detail in locals.tf)"
  default     = true
}

variable "waf_managed_rules" {
  type = list(object({
    name            = string
    priority        = number
    override_action = string
    excluded_rules  = list(string)
  }))
  description = "List of Managed WAF rules."
  default     = []
}

variable "waf_default_action" {
  type        = string
  description = "The action to perform if none of the rules contained in the WebACL match."
  default     = "block"
}

variable "is_enable_waf_cloudwatch_metrics" {
  type        = bool
  description = "The action to perform if none of the rules contained in the WebACL match."
  default     = true
}

variable "is_enable_waf_sampled_requests" {
  type        = bool
  description = "Whether AWS WAF should store a sampling of the web requests that match the rules. You can view the sampled requests through the AWS WAF console."
  default     = true
}

variable "is_create_waf_logging_configuration" {
  type        = bool
  description = "Whether to create logging configuration in order start logging from a WAFv2 Web ACL to CloudWatch"
  default     = true
}

variable "waf_cloudwatch_log_retention_in_days" {
  description = "Specifies the number of days you want to retain log events Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire"
  type        = number
  default     = 90
}

variable "waf_cloudwatch_log_kms_key_id" {
  description = "The ARN for the KMS encryption key."
  type        = string
  default     = null
}

variable "waf_redacted_fields" {
  description = "The parts of the request that you want to keep out of the logs. Up to 100 `redacted_fields` blocks are supported."
  type        = any
  default     = []
}

variable "waf_logging_filter" {
  type        = any
  description = "A configuration block that specifies which web requests are kept in the logs and which are dropped. You can filter on the rule action and on the web request labels that were applied by matching rules during web ACL evaluation."
  default     = {}
}

variable "waf_ip_sets_rule" {
  # List of object need to have consis structure --> cv to any --> and make good description
  type = list(object({
    name               = string
    priority           = number
    ip_set             = list(string)
    action             = string
    ip_address_version = string
  }))
  description = "A rule to detect web requests coming from particular IP addresses or address ranges."
  default     = []
}

variable "waf_ip_rate_based_rule" {
  type = object({
    name     = string
    priority = number
    action   = string
    limit    = number
  })
  description = "A rate-based rule tracks the rate of requests for each originating IP address, and triggers the rule action when the rate exceeds a limit that you specify on the number of requests in any 5-minute time span"
  default     = null
}

variable "waf_custom_rules" {
  description = "Find the example for these structure"
  type        = any
  default     = []
}

variable "waf_ip_set" {
  description = <<EOL
  To create IP set ex.
  ip_sets = {
    "oozou-vpn-ipv4-set" = {
      ip_addresses       = ["127.0.01/32"]
      ip_address_version = "IPV4"
    },
    "oozou-vpn-ipv6-set" = {
      ip_addresses       = ["2403:6200:88a2:a6f8:2096:9b42:31f8:61fd/128"]
      ip_address_version = "IPV6"
    }
  }
  EOL
  type = map(object({
    ip_addresses       = list(string)
    ip_address_version = string
  }))
  default = {}
}

variable "waf_custom_response_body" {
  description = "(optional) Define custom response body"
  type        = list(any)
  default     = []
}

variable "is_staging" {
  description = "if it's staging distribution"
  type        = bool
  default     = false
}

variable "is_create_continuous_deployment_policy" {
  description = "Whether to create continuous deployment policy or not"
  type        = bool
  default     = false
}

variable "staging_domain_name" {
  description = "staging domain name"
  type        = string
  default     = ""
}

variable "traffic_config" {
  type = object({
    type = string
    single_header_config = optional(object({
      header = string
      value  = string
    }))
    single_weight_config = optional(object({
      weight = number
      session_stickiness_config = optional(object({
        idle_ttl    = number
        maximum_ttl = number
      }))
    }))
  })

  default = null
}

variable "minimum_protocol_version" {
  description = "Minimum version of the SSL protocol that you want CloudFront to use for HTTPS connections"
  type        = string
  default     = "TLSv1.2_2021"
}