<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm_virginia"></a> [acm\_virginia](#module\_acm\_virginia) | git::ssh://git@github.com/oozou/terraform-aws-acm.git | v1.0.1 |
| <a name="module_cloudfront_distribution"></a> [cloudfront\_distribution](#module\_cloudfront\_distribution) | ../../ | n/a |
| <a name="module_s3_for_cloudfront_logs"></a> [s3\_for\_cloudfront\_logs](#module\_s3\_for\_cloudfront\_logs) | git@github.com:oozou/terraform-aws-s3.git | v1.0.4 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_custom_tags"></a> [custom\_tags](#input\_custom\_tags) | Custom tags which can be passed on to the AWS resources. They should be key value pairs having distinct keys. | `map(string)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | [Required] Name prefix used for resource naming in this component | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | [Required] Name prefix used for resource naming in this component | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
