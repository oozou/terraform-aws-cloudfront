# Change Log

All notable changes to this module will be documented in this file.

## [v1.3.2] - 2025-06-09

- Add var `minimum_protocol_version` with default vaue `TLSv1.2_2021`

## [v1.3.1] - 2025-06-09

- Update WAF module version to 1.3.1

## [v1.3.0] - 2025-05-20

- Add resrouce and var to support continuous_deployment
  - var: 
    - `is_staging`
    - `is_create_continuous_deployment_policy` 
    - `staging_domain_name`
    - `traffic_config`
  - resource: `aws_cloudfront_continuous_deployment_policy`

## [v1.2.5] - 2025-03-31

- Update WAF module version to v1.3.0
  - Resource: `module.waf`
  - 
## [v1.2.4] - 2025-03-05

- add var custom_error_response to support custom error response
  - Resource: `aws_cloudfront_distribution.distribution`
  - Variable: `custom_error_response`

## [v1.2.3] - 2024-03-27

- Update WAF module version to v1.2.0
  - Resource: `module.waf`
  - 
## [v1.2.2] - 2024-02-23

- add new var for enable/disable distribution and retain_on_delete
  - Resource: `aws_cloudfront_distribution`
  - Variable: `is_enable_distribution` and `retain_on_delete`

## [v1.2.1] - 2023-10-26

- Update WAF module version to v1.1.1
  - Resource: `module.waf`
  - Variable: `waf_custom_response_body`

### Changed

- Add tagging with module name in `local.tags`

## [v1.2.0] - 2023-06-21

### Added

- Add variables `waf_custom_rules` and `waf_ip_set`

### Changed

- WAF module version from `1.0.3` to `1.1.0`

## [v1.1.0] - 2022-12-02

### Added

- Add `output.cloudfront_distribution_arn`
- Add variables `var.name_override`, `var.origin`, `var.origin_group` and `var.origin_access_identities`
- Add locals variables `local.empty_prefix`, `local.empty_environment`, `local.empty_name` and `local.raise_empty_name`
- Add attributes `dynamic "origin"` for all origin in `aws_cloudfront_distribution.distribution`

### Changed

- Update outputs
    - Rename `output.cf_domain_name` to `output.cloudfront_distribution_domain_name`
    - Rename `output.cf_s3_iam_arn` to `cloudfront_origin_access_identities`
- Update local `local.resource_name` to `local.name`
- Update variable description for `var.prefix`, `var.environment` and `var.name`
- Update resource `aws_cloudfront_distribution.distribution` code format
- Update attribute `default_cache_behavior`; `compress`, `min_ttl`, `default_ttl`, `max_ttl` in `aws_cloudfront_distribution.distribution`

### Removed

- Remove files `dns.tf`, `examples/complete/acm.tf`, `examples/complete/s3.tf`, `iam.tf` and `locals.tf`
- Remove variables `var.lambda_function_association`, `var.s3_origin`, `var.origin_read_timeout`, `var.custom_header_token`, `secondary_origin_config` and `var.origin_config`
- Remove resource `aws_cloudfront_origin_access_identity.cloudfront_s3_policy`
- Remove `custom_origin_config`, `dynamic "origin" (s3)`, `dynamic "ordered_cache_behavior" (s3)` attribute in `aws_cloudfront_distribution.distribution`

## [v1.0.7] - 2022-10-25

### Changed

- Update `module/waf` to version `v1.0.3`

## [v1.0.6] - 2022-10-05

### Changed

- Update module `module.waf` to new public version

## [v1.0.5] - 2022-08-17

### Changed

- Update require version of terraform from `>=0.13` to `>=1.0.0`
- Update .pre-commit-config.yaml uncomment `terraform_unused_declarations`
- Update README regard to `versions.tf`

## [v1.0.4] - 2022-08-03

### Added

- add vars `is_automatic_create_dns_record` for enable an option to choose whether to automatically create dns records or not
- dns records is now capable to create record for all cloudfront aliases
- support using cloudfront certificate viewer instead of custom one

### Changed

- remove vars `acm_cert_domain_name`
- vars `domain_aliases` is now only vars that use as cloudfront aliases

## [v1.0.3] - 2022-07-22

### Changed

- freeze terraform-aws-waf version from `develop` to `1.0.2`

## [v1.0.2] - 2022-06-30

### Added

- add default_cache_behavior to support all argument in cloudfront distribution

### Changed

- variables
  - move `caching_config`, `ttl_config` and `allowed_methods` to `default_cache_behavior`

### Added

- init terraform-aws-cloudfront module

## [v1.0.1] - 2022-05-09

### Added

- variables
  - `is_create_log_access_role`

## [v1.0.0] - 2022-04-28

### Added

- init terraform-aws-cloudfront module
