# AWS VPC Cloudfront Module

Terraform module with create Cloudfront resources on AWS.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.98.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_waf"></a> [waf](#module\_waf) | oozou/waf/aws | 1.3.1 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_continuous_deployment_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_continuous_deployment_policy) | resource |
| [aws_cloudfront_distribution.distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_origin_access_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_identity) | resource |
| [aws_iam_role.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_route53_record.application](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.hosted_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cdn_certificate_arn"></a> [cdn\_certificate\_arn](#input\_cdn\_certificate\_arn) | Specify ARN for CDN certificate | `string` | `null` | no |
| <a name="input_custom_error_response"></a> [custom\_error\_response](#input\_custom\_error\_response) | One or more custom error response elements | `any` | `{}` | no |
| <a name="input_default_cache_behavior"></a> [default\_cache\_behavior](#input\_default\_cache\_behavior) | Specify CloudFront configuration related to caching behavior | `any` | <pre>{<br>  "allowed_methods": [<br>    "DELETE",<br>    "GET",<br>    "HEAD",<br>    "OPTIONS",<br>    "PATCH",<br>    "POST",<br>    "PUT"<br>  ],<br>  "cached_methods": [<br>    "GET",<br>    "HEAD"<br>  ],<br>  "compress": true,<br>  "cookies_forward": "none",<br>  "cookies_whitelisted_names": [],<br>  "default_ttl": 3600,<br>  "headers": [<br>    "Host"<br>  ],<br>  "max_ttl": 86400,<br>  "min_ttl": 0,<br>  "query_string": false,<br>  "query_string_cache_keys": []<br>}</pre> | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | File name for default root object | `string` | `"index.html"` | no |
| <a name="input_domain_aliases"></a> [domain\_aliases](#input\_domain\_aliases) | CNAMEs (domain names) for the distribution | `list(string)` | `[]` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | (Optional) Environment as a part of format("%s-%s-%s-cf", var.prefix, var.environment, var.name); ex. xxx-prod-xxx-cf | `string` | `""` | no |
| <a name="input_geo_restriction_config"></a> [geo\_restriction\_config](#input\_geo\_restriction\_config) | Specify configuration for restriction based on location | <pre>object({<br>    geo_restriction_type      = string       # Method that use to restrict distribution of your content by country: `none`, `whitelist`, or `blacklist<br>    geo_restriction_locations = list(string) # List of country codes for which CloudFront either to distribute content (whitelist) or not distribute your content (blacklist)<br>  })</pre> | <pre>{<br>  "geo_restriction_locations": [],<br>  "geo_restriction_type": "none"<br>}</pre> | no |
| <a name="input_is_automatic_create_dns_record"></a> [is\_automatic\_create\_dns\_record](#input\_is\_automatic\_create\_dns\_record) | Whether to automatically create cloudfront A record. | `bool` | `true` | no |
| <a name="input_is_create_continuous_deployment_policy"></a> [is\_create\_continuous\_deployment\_policy](#input\_is\_create\_continuous\_deployment\_policy) | Whether to create continuous deployment policy or not | `bool` | `false` | no |
| <a name="input_is_create_log_access_role"></a> [is\_create\_log\_access\_role](#input\_is\_create\_log\_access\_role) | Whether to create log access role or not; just make role no relate resource in this module used | `bool` | `true` | no |
| <a name="input_is_create_waf_logging_configuration"></a> [is\_create\_waf\_logging\_configuration](#input\_is\_create\_waf\_logging\_configuration) | Whether to create logging configuration in order start logging from a WAFv2 Web ACL to CloudWatch | `bool` | `true` | no |
| <a name="input_is_enable_distribution"></a> [is\_enable\_distribution](#input\_is\_enable\_distribution) | enable or disable distribution | `bool` | `true` | no |
| <a name="input_is_enable_waf"></a> [is\_enable\_waf](#input\_is\_enable\_waf) | Whether to enable WAF for CloudFront | `bool` | `false` | no |
| <a name="input_is_enable_waf_cloudwatch_metrics"></a> [is\_enable\_waf\_cloudwatch\_metrics](#input\_is\_enable\_waf\_cloudwatch\_metrics) | The action to perform if none of the rules contained in the WebACL match. | `bool` | `true` | no |
| <a name="input_is_enable_waf_default_rule"></a> [is\_enable\_waf\_default\_rule](#input\_is\_enable\_waf\_default\_rule) | If true with enable default rule (detail in locals.tf) | `bool` | `true` | no |
| <a name="input_is_enable_waf_sampled_requests"></a> [is\_enable\_waf\_sampled\_requests](#input\_is\_enable\_waf\_sampled\_requests) | Whether AWS WAF should store a sampling of the web requests that match the rules. You can view the sampled requests through the AWS WAF console. | `bool` | `true` | no |
| <a name="input_is_ipv6_enabled"></a> [is\_ipv6\_enabled](#input\_is\_ipv6\_enabled) | State of CloudFront IPv6 | `bool` | `true` | no |
| <a name="input_is_staging"></a> [is\_staging](#input\_is\_staging) | if it's staging distribution | `bool` | `false` | no |
| <a name="input_log_aggregation_s3_bucket_name"></a> [log\_aggregation\_s3\_bucket\_name](#input\_log\_aggregation\_s3\_bucket\_name) | [Required] S3 bucket name where logs are stored for cloudfront | `string` | n/a | yes |
| <a name="input_log_include_cookies"></a> [log\_include\_cookies](#input\_log\_include\_cookies) | Include cookies in access logs | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | (Optional) Name as a part of format("%s-%s-%s-cf", var.prefix, var.environment, var.name); ex. xxx-xxx-cms-cf | `string` | `""` | no |
| <a name="input_name_override"></a> [name\_override](#input\_name\_override) | (Optional) Full name to override usage from format("%s-%s-%s-cf", var.prefix, var.environment, var.name) | `string` | `""` | no |
| <a name="input_ordered_cache_behaviors"></a> [ordered\_cache\_behaviors](#input\_ordered\_cache\_behaviors) | An ordered list of cache behaviors resource for this distribution. List from top to bottom in order of precedence. The topmost cache behavior will have precedence 0. | `any` | `[]` | no |
| <a name="input_origin"></a> [origin](#input\_origin) | One or more origins for this distribution (multiples allowed). | `any` | `{}` | no |
| <a name="input_origin_access_identities"></a> [origin\_access\_identities](#input\_origin\_access\_identities) | Map of CloudFront origin access identities (value as a comment) | `map(string)` | `{}` | no |
| <a name="input_origin_group"></a> [origin\_group](#input\_origin\_group) | One or more origin\_group for this distribution (multiples allowed). | `any` | `{}` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | (Optional) Prefix as a part of format("%s-%s-%s-cf", var.prefix, var.environment, var.name); ex. oozou-xxx-xxx-cf | `string` | `""` | no |
| <a name="input_price_class"></a> [price\_class](#input\_price\_class) | Price class for this distribution: `PriceClass_All`, `PriceClass_200`, `PriceClass_100` (price class denotes the edge locations which are supported by CDN) | `string` | `"PriceClass_100"` | no |
| <a name="input_retain_on_delete"></a> [retain\_on\_delete](#input\_retain\_on\_delete) | retain cloudfront when destroy | `bool` | `true` | no |
| <a name="input_route53_domain_name"></a> [route53\_domain\_name](#input\_route53\_domain\_name) | [Required] The Name of the already existing Route53 Hosted Zone (i.e.: 'spike.abc.cloud') | `string` | `null` | no |
| <a name="input_staging_domain_name"></a> [staging\_domain\_name](#input\_staging\_domain\_name) | staging domain name | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Custom tags which can be passed on to the AWS resources. They should be key value pairs having distinct keys. | `map(string)` | `{}` | no |
| <a name="input_traffic_config"></a> [traffic\_config](#input\_traffic\_config) | n/a | <pre>object({<br>    type = string<br>    single_header_config = optional(object({<br>      header = string<br>      value  = string<br>    }))<br>    single_weight_config = optional(object({<br>      weight = number<br>      session_stickiness_config = optional(object({<br>        idle_ttl    = number<br>        maximum_ttl = number<br>      }))<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_waf_cloudwatch_log_kms_key_id"></a> [waf\_cloudwatch\_log\_kms\_key\_id](#input\_waf\_cloudwatch\_log\_kms\_key\_id) | The ARN for the KMS encryption key. | `string` | `null` | no |
| <a name="input_waf_cloudwatch_log_retention_in_days"></a> [waf\_cloudwatch\_log\_retention\_in\_days](#input\_waf\_cloudwatch\_log\_retention\_in\_days) | Specifies the number of days you want to retain log events Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire | `number` | `90` | no |
| <a name="input_waf_custom_response_body"></a> [waf\_custom\_response\_body](#input\_waf\_custom\_response\_body) | (optional) Define custom response body | `list(any)` | `[]` | no |
| <a name="input_waf_custom_rules"></a> [waf\_custom\_rules](#input\_waf\_custom\_rules) | Find the example for these structure | `any` | `[]` | no |
| <a name="input_waf_default_action"></a> [waf\_default\_action](#input\_waf\_default\_action) | The action to perform if none of the rules contained in the WebACL match. | `string` | `"block"` | no |
| <a name="input_waf_ip_rate_based_rule"></a> [waf\_ip\_rate\_based\_rule](#input\_waf\_ip\_rate\_based\_rule) | A rate-based rule tracks the rate of requests for each originating IP address, and triggers the rule action when the rate exceeds a limit that you specify on the number of requests in any 5-minute time span | <pre>object({<br>    name     = string<br>    priority = number<br>    action   = string<br>    limit    = number<br>  })</pre> | `null` | no |
| <a name="input_waf_ip_set"></a> [waf\_ip\_set](#input\_waf\_ip\_set) | To create IP set ex.<br>  ip\_sets = {<br>    "oozou-vpn-ipv4-set" = {<br>      ip\_addresses       = ["127.0.01/32"]<br>      ip\_address\_version = "IPV4"<br>    },<br>    "oozou-vpn-ipv6-set" = {<br>      ip\_addresses       = ["2403:6200:88a2:a6f8:2096:9b42:31f8:61fd/128"]<br>      ip\_address\_version = "IPV6"<br>    }<br>  } | <pre>map(object({<br>    ip_addresses       = list(string)<br>    ip_address_version = string<br>  }))</pre> | `{}` | no |
| <a name="input_waf_ip_sets_rule"></a> [waf\_ip\_sets\_rule](#input\_waf\_ip\_sets\_rule) | A rule to detect web requests coming from particular IP addresses or address ranges. | <pre>list(object({<br>    name               = string<br>    priority           = number<br>    ip_set             = list(string)<br>    action             = string<br>    ip_address_version = string<br>  }))</pre> | `[]` | no |
| <a name="input_waf_logging_filter"></a> [waf\_logging\_filter](#input\_waf\_logging\_filter) | A configuration block that specifies which web requests are kept in the logs and which are dropped. You can filter on the rule action and on the web request labels that were applied by matching rules during web ACL evaluation. | `any` | `{}` | no |
| <a name="input_waf_managed_rules"></a> [waf\_managed\_rules](#input\_waf\_managed\_rules) | List of Managed WAF rules. | <pre>list(object({<br>    name            = string<br>    priority        = number<br>    override_action = string<br>    excluded_rules  = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_waf_redacted_fields"></a> [waf\_redacted\_fields](#input\_waf\_redacted\_fields) | The parts of the request that you want to keep out of the logs. Up to 100 `redacted_fields` blocks are supported. | `any` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudfront_distribution_arn"></a> [cloudfront\_distribution\_arn](#output\_cloudfront\_distribution\_arn) | The ARN (Amazon Resource Name) for the distribution. |
| <a name="output_cloudfront_distribution_domain_name"></a> [cloudfront\_distribution\_domain\_name](#output\_cloudfront\_distribution\_domain\_name) | The domain name corresponding to the distribution. For example: d604721fxaaqy9.cloudfront.net |
| <a name="output_cloudfront_origin_access_identities"></a> [cloudfront\_origin\_access\_identities](#output\_cloudfront\_origin\_access\_identities) | A pre-generated ARN for use in S3 bucket policies (see below). Example: arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E2QWRUHAPOMQZL. |
<!-- END_TF_DOCS -->
