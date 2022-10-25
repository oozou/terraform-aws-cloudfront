# AWS VPC Cloudfront Module

Terraform module with create Cloudfront resources on AWS.

```terraform
module "cloudfront_distribution" {
  source = "git@github.com:oozou/terraform-aws-cloudfront.git?ref=<selected_version>"

  prefix      = "oozou"
  name        = "cms"
  environment = "dev"

  # CDN variables
  origin_config = {
    origin_domain_name = "alb.oozou-develop.oo-m.me"
    origin_id          = "alb.oozou-develop.oo-m.me"
  }

  # To attach token with header `custom-header-token` = var.custom_header_token
  custom_header_token = "asjdhkjdhfkahdfkjahsdkfjhakdsjfkasdjhasjkhe" # Defualt "", no additional custom token

  domain_aliases = ["cdn.oozou-develop.oo-m.me","web.oozou-develop.oo-m.me", "api.oozou-develop.oo-m.me"]

  # Default behavior
  caching_config = {
    forwarded_headers                 = ["Origin", "Authorization", "Referer", "Host", "Accept-Language", "Accept", "user-agent"]
    forward_cookies                   = "all"
    forward_cookies_whitelisted_names = []
    forward_query_string              = true
    cached_methods                    = ["GET", "HEAD"]
    compress                          = true
  }
  ttl_config = {
    default_ttl = 0
    min_ttl     = 0
    max_ttl     = 0
  }

  # For s3 cloudfront origin
  s3_origin = {
    is_create_oai          = false
    origin_domain_name     = "oozou-dev-cms-bucket-011275294601-wf2lxe.s3.ap-southeast-1.amazonaws.com"
    origin_id              = "oozou-dev-cms-bucket-011275294601-wf2lxe"
    path_pattern           = "/uploads/*"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
  }
  lambda_function_association = {
    event_type   = "origin-request"
    lambda_arn   = "arn:aws:lambda:us-east-1:${data.aws_caller_identity.current.account_id}:function:sigv4-request-to-s3:1"
    include_body = false
  }

  # Custom behavior
  ordered_cache_behaviors = [
    {
      path_pattern           = "/mobile/*",
      target_origin_id       = "alb.oozou-develop.oo-m.me",
      viewer_protocol_policy = "redirect-to-https",

      allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"],
      compress        = true,

      query_string            = true,
      query_string_cache_keys = [],
      headers                 = ["Accept", "Accept-Language", "Authorization", "Host", "Origin", "Referer", "user-agent"],

      cookies_forward = "all",

      min_ttl     = 0,
      default_ttl = 30,
      max_ttl     = 60,

      response_headers_policy_id = null
    },
    {
      path_pattern           = "/_next/*",
      target_origin_id       = "alb.oozou-develop.oo-m.me",
      viewer_protocol_policy = "redirect-to-https",

      allowed_methods = ["GET", "HEAD", "OPTIONS"],
      compress        = true,

      query_string            = true,
      query_string_cache_keys = [],
      headers                 = ["Host"],

      cookies_forward = "all",

      min_ttl     = 0,
      default_ttl = 86400,
      max_ttl     = 31536000,

      response_headers_policy_id = null
    },
  ]

  log_aggregation_s3_bucket_name = "sbth-uat-cms-cdn-log-bucket-kmayuh"

  # DNS Mapping variables
  is_automatic_create_dns_record = true
  cdn_certificate_arn            = "arn:aws:acm:ap-southeast-1:011275294601:certificate/3826abc-c140-4c13-acc1-8668c038c20a"
  route53_domain_name            = "oozou-develop.oo-m.me"

  # Waf
  is_enable_waf              = true # If  is_enable_waf is `false`, all of fllowing variables are ignored
  is_enable_waf_default_rule = true
  waf_default_action         = "allow"
  waf_ip_sets_rule = [
    {
      name               = "count-ip-set"
      priority           = 5
      action             = "count"
      ip_address_version = "IPV4"
      ip_set             = ["1.2.3.4/32", "5.6.7.8/32"]
    },
    {
      name               = "block-ip-set"
      priority           = 6
      action             = "block"
      ip_address_version = "IPV4"
      ip_set             = ["10.0.1.1/32"]
    }
  ]
  waf_ip_rate_based_rule = {
    name : "ip-rate-limit",
    priority : 7,
    action : "block",
    limit : 100
  }

  tags = { "Workspace" : "xxx" }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name                                                                      | Version  |
|---------------------------------------------------------------------------|----------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws)                   | >= 4.0.0 |

## Providers

| Name                                              | Version |
|---------------------------------------------------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.8.0   |

## Modules

| Name                                          | Source        | Version |
|-----------------------------------------------|---------------|---------|
| <a name="module_waf"></a> [waf](#module\_waf) | oozou/waf/aws | 1.0.3   |

## Resources

| Name                                                                                                                                                                        | Type        |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [aws_cloudfront_distribution.distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution)                             | resource    |
| [aws_cloudfront_origin_access_identity.cloudfront_s3_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_identity) | resource    |
| [aws_iam_role.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                                                   | resource    |
| [aws_iam_role_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy)                                                     | resource    |
| [aws_route53_record.application](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)                                                | resource    |
| [aws_route53_zone.hosted_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone)                                                 | data source |

## Inputs

| Name                                                                                                     | Description                                                       | Type           | Default                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | Required |
|----------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|----------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------:|
| <a name="input_cdn_certificate_arn"></a> [cdn\_certificate\_arn](#input\_cdn\_certificate\_arn)          | Specify ARN for CDN certificate                                   | `string`       | `null`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |    no    |
| <a name="input_custom_header_token"></a> [custom\_header\_token](#input\_custom\_header\_token)          | [Required] Specify secret value for custom header                 | `string`       | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |   yes    |
| <a name="input_default_cache_behavior"></a> [default\_cache\_behavior](#input\_default\_cache\_behavior) | Specify CloudFront configuration related to caching behavior      | `any`          | <pre>{<br>  "allowed_methods": [<br>    "DELETE",<br>    "GET",<br>    "HEAD",<br>    "OPTIONS",<br>    "PATCH",<br>    "POST",<br>    "PUT"<br>  ],<br>  "cached_methods": [<br>    "GET",<br>    "HEAD"<br>  ],<br>  "compress": true,<br>  "cookies_forward": "none",<br>  "cookies_whitelisted_names": [],<br>  "default_ttl": 3600,<br>  "headers": [<br>    "Host"<br>  ],<br>  "max_ttl": 86400,<br>  "min_ttl": 0,<br>  "query_string": false,<br>  "query_string_cache_keys": []<br>}</pre> |    no    |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object)          | File name for default root object                                 | `string`       | `"index.html"`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |    no    |
| <a name="input_domain_aliases"></a> [domain\_aliases](#input\_domain\_aliases)                           | CNAMEs (domain names) for the distribution                        | `list(string)` | `[]`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |    no    |
| <a name="input_environment"></a> [environment](#input\_environment)                                      | [Required] Name prefix used for resource naming in this component | `string`       | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |   yes    |
| <a name="input_geo_restriction_config"></a> [geo\_restriction\_config](#input\_geo\_restriction\_config) | Specify configuration for restriction based on location | <pre>object({<br>    geo_restriction_type      = string       # Method that use to restrict distribution of your content by country: `none`, `whitelist`, or `blacklist<br>    geo_restriction_locations = list(string) # List of country codes for which CloudFront either to distribute content (whitelist) or not distribute your content (blacklist)<br>  })</pre> | <pre>{<br>  "geo_restriction_locations": [],<br>  "geo_restriction_type": "none"<br>}</pre> | no |
| <a name="input_is_automatic_create_dns_record"></a> [is\_automatic\_create\_dns\_record](#input\_is\_automatic\_create\_dns\_record) | Whether to automatically create cloudfront A record. | `bool` | `true` | no |
| <a name="input_is_create_log_access_role"></a> [is\_create\_log\_access\_role](#input\_is\_create\_log\_access\_role) | Whether to create log access role or not; just make role no relate resource in this module used | `bool` | `true` | no |
| <a name="input_is_create_waf_logging_configuration"></a> [is\_create\_waf\_logging\_configuration](#input\_is\_create\_waf\_logging\_configuration) | Whether to create logging configuration in order start logging from a WAFv2 Web ACL to CloudWatch | `bool` | `true` | no |
| <a name="input_is_enable_waf"></a> [is\_enable\_waf](#input\_is\_enable\_waf) | Whether to enable WAF for CloudFront | `bool` | `false` | no |
| <a name="input_is_enable_waf_cloudwatch_metrics"></a> [is\_enable\_waf\_cloudwatch\_metrics](#input\_is\_enable\_waf\_cloudwatch\_metrics) | The action to perform if none of the rules contained in the WebACL match. | `bool` | `true` | no |
| <a name="input_is_enable_waf_default_rule"></a> [is\_enable\_waf\_default\_rule](#input\_is\_enable\_waf\_default\_rule) | If true with enable default rule (detail in locals.tf) | `bool` | `true` | no |
| <a name="input_is_enable_waf_sampled_requests"></a> [is\_enable\_waf\_sampled\_requests](#input\_is\_enable\_waf\_sampled\_requests) | Whether AWS WAF should store a sampling of the web requests that match the rules. You can view the sampled requests through the AWS WAF console. | `bool` | `true` | no |
| <a name="input_is_ipv6_enabled"></a> [is\_ipv6\_enabled](#input\_is\_ipv6\_enabled) | State of CloudFront IPv6 | `bool` | `true` | no |
| <a name="input_lambda_function_association"></a> [lambda\_function\_association](#input\_lambda\_function\_association) | The lambda assosiation used with encrypted s3 | <pre>object({<br>    event_type   = string<br>    lambda_arn   = string<br>    include_body = bool<br>  })</pre> | `null` | no |
| <a name="input_log_aggregation_s3_bucket_name"></a> [log\_aggregation\_s3\_bucket\_name](#input\_log\_aggregation\_s3\_bucket\_name) | [Required] S3 bucket name where logs are stored for cloudfront | `string` | n/a | yes |
| <a name="input_log_include_cookies"></a> [log\_include\_cookies](#input\_log\_include\_cookies) | Include cookies in access logs | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | [Required] Name prefix used for resource naming in this component | `string` | n/a | yes |
| <a name="input_ordered_cache_behaviors"></a> [ordered\_cache\_behaviors](#input\_ordered\_cache\_behaviors) | An ordered list of cache behaviors resource for this distribution. List from top to bottom in order of precedence. The topmost cache behavior will have precedence 0. | `any` | `[]` | no |
| <a name="input_origin_config"></a> [origin\_config](#input\_origin\_config) | [Required] Specify configuration related to Origin | <pre>object({<br>    origin_domain_name = string # Specify domain name for the origin such as a S3 bucket or any web server from which CloudFront is going to get web content<br>    origin_id          = string # Specify origin id. This value assist in distinguishing multiple origins in the same distribution from one another. Origin id must be unique within the distribution.<br>  })</pre> | n/a | yes |
| <a name="input_origin_read_timeout"></a> [origin\_read\_timeout](#input\_origin\_read\_timeout) | Read timeout value specifies the amount of time CloudFront will wait for a response from the custom origin (this should be insync with your origin (like ALB) timeout) | `number` | `60` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | [Required] Name prefix used for resource naming in this component | `string` | n/a | yes |
| <a name="input_price_class"></a> [price\_class](#input\_price\_class) | Price class for this distribution: `PriceClass_All`, `PriceClass_200`, `PriceClass_100` (price class denotes the edge locations which are supported by CDN) | `string` | `"PriceClass_100"` | no |
| <a name="input_route53_domain_name"></a> [route53\_domain\_name](#input\_route53\_domain\_name) | [Required] The Name of the already existing Route53 Hosted Zone (i.e.: 'spike.abc.cloud') | `string` | `null` | no |
| <a name="input_s3_origin"></a> [s3\_origin](#input\_s3\_origin) | Specify configuration related to Origin S3 | <pre>object({<br>    path_pattern           = string<br>    allowed_methods        = list(string)<br>    cached_methods         = list(string)<br>    origin_domain_name     = string<br>    origin_id              = string<br>    viewer_protocol_policy = string<br>    is_create_oai          = bool<br>  })</pre> | `null` | no |
| <a name="input_secondary_origin_config"></a> [secondary\_origin\_config](#input\_secondary\_origin\_config) | Specify configuration related to secondary origin. This origin will be used for high availability with CloudFront primary origin | <pre>object({<br>    secondary_domain_name = string # Specify domain name for the origin such as a S3 bucket or any web server from which CloudFront is going to get web content<br>    secondary_origin_id   = string # Specify origin id. This value assist in distinguishing multiple origins in the same distribution from one another. Origin id must be unique within the distribution.<br>  })</pre> | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Custom tags which can be passed on to the AWS resources. They should be key value pairs having distinct keys. | `map(string)` | `{}` | no |
| <a name="input_waf_cloudwatch_log_kms_key_id"></a> [waf\_cloudwatch\_log\_kms\_key\_id](#input\_waf\_cloudwatch\_log\_kms\_key\_id) | The ARN for the KMS encryption key. | `string` | `null` | no |
| <a name="input_waf_cloudwatch_log_retention_in_days"></a> [waf\_cloudwatch\_log\_retention\_in\_days](#input\_waf\_cloudwatch\_log\_retention\_in\_days) | Specifies the number of days you want to retain log events Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire | `number` | `90` | no |
| <a name="input_waf_default_action"></a> [waf\_default\_action](#input\_waf\_default\_action) | The action to perform if none of the rules contained in the WebACL match. | `string` | `"block"` | no |
| <a name="input_waf_ip_rate_based_rule"></a> [waf\_ip\_rate\_based\_rule](#input\_waf\_ip\_rate\_based\_rule) | A rate-based rule tracks the rate of requests for each originating IP address, and triggers the rule action when the rate exceeds a limit that you specify on the number of requests in any 5-minute time span | <pre>object({<br>    name     = string<br>    priority = number<br>    action   = string<br>    limit    = number<br>  })</pre> | `null` | no |
| <a name="input_waf_ip_sets_rule"></a> [waf\_ip\_sets\_rule](#input\_waf\_ip\_sets\_rule) | A rule to detect web requests coming from particular IP addresses or address ranges. | <pre>list(object({<br>    name               = string<br>    priority           = number<br>    ip_set             = list(string)<br>    action             = string<br>    ip_address_version = string<br>  }))</pre> | `[]` | no |
| <a name="input_waf_logging_filter"></a> [waf\_logging\_filter](#input\_waf\_logging\_filter) | A configuration block that specifies which web requests are kept in the logs and which are dropped. You can filter on the rule action and on the web request labels that were applied by matching rules during web ACL evaluation. | `any` | `{}` | no |
| <a name="input_waf_managed_rules"></a> [waf\_managed\_rules](#input\_waf\_managed\_rules) | List of Managed WAF rules. | <pre>list(object({<br>    name            = string<br>    priority        = number<br>    override_action = string<br>    excluded_rules  = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_waf_redacted_fields"></a> [waf\_redacted\_fields](#input\_waf\_redacted\_fields) | The parts of the request that you want to keep out of the logs. Up to 100 `redacted_fields` blocks are supported. | `any` | `[]` | no |

## Outputs

| Name                                                                               | Description                                                                                                                                            |
|------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| <a name="output_cf_domain_name"></a> [cf\_domain\_name](#output\_cf\_domain\_name) | The domain name corresponding to the distribution. For example: d604721fxaaqy9.cloudfront.net                                                          |
| <a name="output_cf_s3_iam_arn"></a> [cf\_s3\_iam\_arn](#output\_cf\_s3\_iam\_arn)  | A pre-generated ARN for use in S3 bucket policies (see below). Example: arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E2QWRUHAPOMQZL. |
<!-- END_TF_DOCS -->
