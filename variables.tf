# CDN variables

variable "origin_config" {
  description = "[Required] Specify configuration related to Origin"
  type = object({
    origin_domain_name = string # Specify domain name for the origin such as a S3 bucket or any web server from which CloudFront is going to get web content
    origin_id          = string # Specify origin id. This value assist in distinguishing multiple origins in the same distribution from one another. Origin id must be unique within the distribution.
  })
}

variable "secondary_origin_config" {
  description = "Specify configuration related to secondary origin. This origin will be used for high availability with CloudFront primary origin"
  type = object({
    secondary_domain_name = string # Specify domain name for the origin such as a S3 bucket or any web server from which CloudFront is going to get web content
    secondary_origin_id   = string # Specify origin id. This value assist in distinguishing multiple origins in the same distribution from one another. Origin id must be unique within the distribution.
  })
  default = null
}

variable "base_name" {
  description = "[Required] Name prefix used for resource naming in this component"
  type        = string
}

variable "account_alias" {
  description = "Alias of the AWS account where this service is created. Eg. alpha/beta/prod. This would be used create s3 bucket path in the logging account"
  type        = string
}

variable "custom_header_token" {
  description = "[Required] Specify secret value for custom header"
  type        = string
}

variable "log_aggregation_s3_bucket_name" {
  description = "[Required] S3 bucket name where logs are stored for cloudfront"
  type        = string
}

variable "domain_aliases" {
  description = "Extra CNAMEs (alternate domain names) for the distribution (apart from FQDN for which SSL certificate is issued, it will be added by-default)"
  type        = list(string)
  default     = []
}

variable "price_class" {
  description = "Price class for this distribution: `PriceClass_All`, `PriceClass_200`, `PriceClass_100` (price class denotes the edge locations which are supported by CDN)"
  type        = string
  default     = "PriceClass_100" # By-default supporting edge locations only in USA and Europe
}

variable "custom_tags" {
  description = "Custom tags which can be passed on to the AWS resources. They should be key value pairs having distinct keys."
  type        = map(string)
  default     = {}
}

variable "caching_config" {
  description = "Specify CloudFront configuration related to caching behavior"
  type = object({
    forwarded_headers                 = list(string) # Specifies the Headers, if any, that you want CloudFront to vary upon for the cache behavior. Specify `*` to include all headers. 'none' is not a valid option for HTTPS connection
    forward_cookies                   = string       # Specifies whether you want CloudFront to forward cookies to the origin. Valid options are all, none or whitelist
    forward_cookies_whitelisted_names = list(string) # List of forwarded cookie names
    forward_query_string              = bool         # Forward query strings to the origin that is associated with this cache behavior
    cached_methods                    = list(string) # List of cached methods (e.g. ` GET, PUT, POST, DELETE, HEAD`)
  })
  default = {
    forwarded_headers                 = ["Host"]
    forward_cookies                   = "none"
    forward_cookies_whitelisted_names = []
    forward_query_string              = false
    cached_methods                    = ["GET", "HEAD"]
  }
}

variable "ttl_config" {
  description = "Specify Time To Live (TTL) configuration for CloudFront"
  type = object({
    default_ttl = number #Default amount of time (in seconds) that an object is in a CloudFront cache, after this time CDN makes a fresh call to origin
    min_ttl     = number #Minimum amount of time that you want objects to stay in CloudFront caches
    max_ttl     = number #Maximum amount of time (in seconds) that an object is in a CloudFront cache
  })
  default = {
    default_ttl = 3600 # 1hour
    min_ttl     = 0
    max_ttl     = 86400 # 24hours
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

variable "is_ipv6_enabled" {
  description = "State of CloudFront IPv6"
  type        = bool
  default     = true
}

variable "allowed_methods" {
  # The parameter AllowedMethods cannot include POST, PUT, PATCH, or DELETE for a cached behavior associated with an origin group.
  description = "List of allowed methods (e.g. ` GET, PUT, POST, DELETE, HEAD`) for AWS CloudFront"
  type        = list(string)
  default     = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
}

variable "log_include_cookies" {
  description = "Include cookies in access logs"
  type        = bool
  default     = false
}

variable "origin_read_timeout" {
  description = "Read timeout value specifies the amount of time CloudFront will wait for a response from the custom origin (this should be insync with your origin (like ALB) timeout)"
  type        = number
  default     = 60
}

#  ACM variables
# domain name for the created CDN
variable "acm_cert_domain_name" {
  description = "[Required] The FQDN of the certificate to issue (i.e.: 'prime.spike.abc.cloud'). The Route53 zone must already exist."
  type        = string
}

# name of the hosted zone for the route 53 record for CDN
variable "route53_domain_name" {
  description = "[Required] The Name of the already existing Route53 Hosted Zone (i.e.: 'spike.abc.cloud')"
  type        = string
}

# Global WAF variables
variable "blacklisted_ips" {
  description = "List of IP addresses to blacklist for access to the application. Format of each entry is a map like: { type='IPV4' value='<ip>/32' }"
  type = list(object({
    type  = string
    value = string
  }))
  default = []
}

variable "whitelisted_ips" {
  description = "List of IP addresses to whitelist for access to the application. Format of each entry is a map like: { type='IPV4' value='<ip>/32' }"
  type = list(object({
    type  = string
    value = string
  }))
  default = []
}

variable "admin_remote_ipset" {
  description = "List of IP addresses to whitelist for access to the /admin route. Format of each entry is a map like: { type='IPV4' value='<ip>/32' }"
  type = list(object({
    type  = string
    value = string
  }))
  default = []
}

variable "default_action" {
  description = "The default action to take if no rules match (BLOCK, ALLOW, or COUNT)"
  default     = "BLOCK"
  type        = string
}

variable "cdn_certificate_arn" {
  description = "Specify ARN for CDN certificate"
  type        = string
}

variable "default_root_object" {
  description = "File name for default root object"
  type        = string
  default     = "index.html"
}

variable "s3_origin" {
  description = "Specify configuration related to Origin S3"
  type = object({
    path_pattern                      = string
    allowed_methods                   = list(string)
    cached_methods                    = list(string)
    origin_domain_name                = string
    origin_id                         = string
  })
  default = null
}

variable "lambda_function_association"{
  description = "The lambda assosiation used with encrypted s3"
  type = object({
    event_type                        = string
    lambda_arn                        = string
    include_body                      = bool
  })
  default = null
}