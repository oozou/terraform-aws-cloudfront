<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_iam_role.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_route53_record.application](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.hosted_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_alias"></a> [account\_alias](#input\_account\_alias) | Alias of the AWS account where this service is created. Eg. alpha/beta/prod. This would be used create s3 bucket path in the logging account | `string` | n/a | yes |
| <a name="input_acm_cert_domain_name"></a> [acm\_cert\_domain\_name](#input\_acm\_cert\_domain\_name) | [Required] The FQDN of the certificate to issue (i.e.: 'prime.spike.abc.cloud'). The Route53 zone must already exist. | `string` | n/a | yes |
| <a name="input_admin_remote_ipset"></a> [admin\_remote\_ipset](#input\_admin\_remote\_ipset) | List of IP addresses to whitelist for access to the /admin route. Format of each entry is a map like: { type='IPV4' value='<ip>/32' } | <pre>list(object({<br>    type  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| <a name="input_allowed_methods"></a> [allowed\_methods](#input\_allowed\_methods) | List of allowed methods (e.g. ` GET, PUT, POST, DELETE, HEAD`) for AWS CloudFront | `list(string)` | <pre>[<br>  "DELETE",<br>  "GET",<br>  "HEAD",<br>  "OPTIONS",<br>  "PATCH",<br>  "POST",<br>  "PUT"<br>]</pre> | no |
| <a name="input_base_name"></a> [base\_name](#input\_base\_name) | [Required] Name prefix used for resource naming in this component | `string` | n/a | yes |
| <a name="input_blacklisted_ips"></a> [blacklisted\_ips](#input\_blacklisted\_ips) | List of IP addresses to blacklist for access to the application. Format of each entry is a map like: { type='IPV4' value='<ip>/32' } | <pre>list(object({<br>    type  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| <a name="input_caching_config"></a> [caching\_config](#input\_caching\_config) | Specify CloudFront configuration related to caching behavior | <pre>object({<br>    forwarded_headers                 = list(string) # Specifies the Headers, if any, that you want CloudFront to vary upon for the cache behavior. Specify `*` to include all headers. 'none' is not a valid option for HTTPS connection<br>    forward_cookies                   = string       # Specifies whether you want CloudFront to forward cookies to the origin. Valid options are all, none or whitelist<br>    forward_cookies_whitelisted_names = list(string) # List of forwarded cookie names<br>    forward_query_string              = bool         # Forward query strings to the origin that is associated with this cache behavior<br>    cached_methods                    = list(string) # List of cached methods (e.g. ` GET, PUT, POST, DELETE, HEAD`)<br>  })</pre> | <pre>{<br>  "cached_methods": [<br>    "GET",<br>    "HEAD"<br>  ],<br>  "forward_cookies": "none",<br>  "forward_cookies_whitelisted_names": [],<br>  "forward_query_string": false,<br>  "forwarded_headers": [<br>    "Host"<br>  ]<br>}</pre> | no |
| <a name="input_cdn_certificate_arn"></a> [cdn\_certificate\_arn](#input\_cdn\_certificate\_arn) | Specify ARN for CDN certificate | `string` | n/a | yes |
| <a name="input_custom_header_token"></a> [custom\_header\_token](#input\_custom\_header\_token) | [Required] Specify secret value for custom header | `string` | n/a | yes |
| <a name="input_custom_tags"></a> [custom\_tags](#input\_custom\_tags) | Custom tags which can be passed on to the AWS resources. They should be key value pairs having distinct keys. | `map(string)` | `{}` | no |
| <a name="input_default_action"></a> [default\_action](#input\_default\_action) | The default action to take if no rules match (BLOCK, ALLOW, or COUNT) | `string` | `"BLOCK"` | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | File name for default root object | `string` | `"index.html"` | no |
| <a name="input_domain_aliases"></a> [domain\_aliases](#input\_domain\_aliases) | Extra CNAMEs (alternate domain names) for the distribution (apart from FQDN for which SSL certificate is issued, it will be added by-default) | `list(string)` | `[]` | no |
| <a name="input_geo_restriction_config"></a> [geo\_restriction\_config](#input\_geo\_restriction\_config) | Specify configuration for restriction based on location | <pre>object({<br>    geo_restriction_type      = string       # Method that use to restrict distribution of your content by country: `none`, `whitelist`, or `blacklist<br>    geo_restriction_locations = list(string) # List of country codes for which CloudFront either to distribute content (whitelist) or not distribute your content (blacklist)<br>  })</pre> | <pre>{<br>  "geo_restriction_locations": [],<br>  "geo_restriction_type": "none"<br>}</pre> | no |
| <a name="input_is_ipv6_enabled"></a> [is\_ipv6\_enabled](#input\_is\_ipv6\_enabled) | State of CloudFront IPv6 | `bool` | `true` | no |
| <a name="input_lambda_function_association"></a> [lambda\_function\_association](#input\_lambda\_function\_association) | lambda\_function\_association configuration | <pre>object({<br>    event_type                        = string # Specifies the Headers, if any, that you want CloudFront to vary upon for the cache behavior. Specify `*` to include all headers. 'none' is not a valid option for HTTPS connection<br>    lambda_arn                        = string<br>    include_body                      = bool<br>  })</pre> | `null` | no |
| <a name="input_log_aggregation_s3_bucket_name"></a> [log\_aggregation\_s3\_bucket\_name](#input\_log\_aggregation\_s3\_bucket\_name) | [Required] S3 bucket name where logs are stored for cloudfront | `string` | n/a | yes |
| <a name="input_log_include_cookies"></a> [log\_include\_cookies](#input\_log\_include\_cookies) | Include cookies in access logs | `bool` | `false` | no |
| <a name="input_origin_config"></a> [origin\_config](#input\_origin\_config) | [Required] Specify configuration related to Origin | <pre>object({<br>    origin_domain_name = string # Specify domain name for the origin such as a S3 bucket or any web server from which CloudFront is going to get web content<br>    origin_id          = string # Specify origin id. This value assist in distinguishing multiple origins in the same distribution from one another. Origin id must be unique within the distribution.<br>  })</pre> | n/a | yes |
| <a name="input_origin_read_timeout"></a> [origin\_read\_timeout](#input\_origin\_read\_timeout) | Read timeout value specifies the amount of time CloudFront will wait for a response from the custom origin (this should be insync with your origin (like ALB) timeout) | `number` | `60` | no |
| <a name="input_price_class"></a> [price\_class](#input\_price\_class) | Price class for this distribution: `PriceClass_All`, `PriceClass_200`, `PriceClass_100` (price class denotes the edge locations which are supported by CDN) | `string` | `"PriceClass_100"` | no |
| <a name="input_route53_domain_name"></a> [route53\_domain\_name](#input\_route53\_domain\_name) | [Required] The Name of the already existing Route53 Hosted Zone (i.e.: 'spike.abc.cloud') | `string` | n/a | yes |
| <a name="input_s3_origin"></a> [s3\_origin](#input\_s3\_origin) | s3 Origin Configuration | <pre>object({<br>    path_pattern                      = string # Specifies the Headers, if any, that you want CloudFront to vary upon for the cache behavior. Specify `*` to include all headers. 'none' is not a valid option for HTTPS connection<br>    allowed_methods                   = list(string)<br>    cached_methods                    = list(string)<br>    origin_domain_name                = string<br>    origin_id                         = string<br>    # forward_cookies                   = string       # Specifies whether you want CloudFront to forward cookies to the origin. Valid options are all, none or whitelist<br>    # forward_cookies_whitelisted_names = list(string) # List of forwarded cookie names<br>    # forward_query_string              = bool         # Forward query strings to the origin that is associated with this cache behavior<br>    # cached_methods                    = list(string) # List of cached methods (e.g. ` GET, PUT, POST, DELETE, HEAD`)<br>  })</pre> | `null` | no |
| <a name="input_secondary_origin_config"></a> [secondary\_origin\_config](#input\_secondary\_origin\_config) | Specify configuration related to secondary origin. This origin will be used for high availability with CloudFront primary origin | <pre>object({<br>    secondary_domain_name = string # Specify domain name for the origin such as a S3 bucket or any web server from which CloudFront is going to get web content<br>    secondary_origin_id   = string # Specify origin id. This value assist in distinguishing multiple origins in the same distribution from one another. Origin id must be unique within the distribution.<br>  })</pre> | `null` | no |
| <a name="input_ttl_config"></a> [ttl\_config](#input\_ttl\_config) | Specify Time To Live (TTL) configuration for CloudFront | <pre>object({<br>    default_ttl = number #Default amount of time (in seconds) that an object is in a CloudFront cache, after this time CDN makes a fresh call to origin<br>    min_ttl     = number #Minimum amount of time that you want objects to stay in CloudFront caches<br>    max_ttl     = number #Maximum amount of time (in seconds) that an object is in a CloudFront cache<br>  })</pre> | <pre>{<br>  "default_ttl": 3600,<br>  "max_ttl": 86400,<br>  "min_ttl": 0<br>}</pre> | no |
| <a name="input_whitelisted_ips"></a> [whitelisted\_ips](#input\_whitelisted\_ips) | List of IP addresses to whitelist for access to the application. Format of each entry is a map like: { type='IPV4' value='<ip>/32' } | <pre>list(object({<br>    type  = string<br>    value = string<br>  }))</pre> | `[]` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->