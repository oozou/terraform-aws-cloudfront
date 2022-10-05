# Change Log

All notable changes to this module will be documented in this file.

## [1.0.5] - 2022-08-17

### Changed

- Update module `module.waf` to new public version

## [1.0.5] - 2022-08-17

### Changed

- Update require version of terraform from `>=0.13` to `>=1.0.0`
- Update .pre-commit-config.yaml uncomment `terraform_unused_declarations`
- Update README regard to `versions.tf`

## [1.0.4] - 2022-08-03

### Added

- add vars `is_automatic_create_dns_record` for enable an option to choose whether to automatically create dns records or not
- dns records is now capable to create record for all cloudfront aliases
- support using cloudfront certificate viewer instead of custom one

### Changed

- remove vars `acm_cert_domain_name`
- vars `domain_aliases` is now only vars that use as cloudfront aliases

## [1.0.3] - 2022-07-22

### Changed

- freeze terraform-aws-waf version from `develop` to `1.0.2`

## [1.0.2] - 2022-06-30

### Added

- add default_cache_behavior to support all argument in cloudfront distribution

### Changed

- variables
  - move `caching_config`, `ttl_config` and `allowed_methods` to `default_cache_behavior`

### Added

- init terraform-aws-cloudfront module

## [1.0.1] - 2022-05-09

### Added

- variables
  - `is_create_log_access_role`

## [1.0.0] - 2022-04-28

### Added

- init terraform-aws-cloudfront module
