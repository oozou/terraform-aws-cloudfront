<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name                                              | Version |
|---------------------------------------------------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.44.0  |

## Modules

| Name                                                                                                               | Source                        | Version |
|--------------------------------------------------------------------------------------------------------------------|-------------------------------|---------|
| <a name="module_cloudfront_distribution"></a> [cloudfront\_distribution](#module\_cloudfront\_distribution)        | ../../                        | n/a     |
| <a name="module_fargate_cluster"></a> [fargate\_cluster](#module\_fargate\_cluster)                                | oozou/ecs-fargate-cluster/aws | 1.0.6   |
| <a name="module_nginx_service"></a> [nginx\_service](#module\_nginx\_service)                                      | oozou/ecs-fargate-service/aws | v1.1.9  |
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket)                                                  | oozou/s3/aws                  | 1.1.3   |
| <a name="module_s3_cloudfront_log_bucket"></a> [s3\_cloudfront\_log\_bucket](#module\_s3\_cloudfront\_log\_bucket) | oozou/s3/aws                  | 1.1.3   |
| <a name="module_vpc"></a> [vpc](#module\_vpc)                                                                      | oozou/vpc/aws                 | 1.2.4   |

## Resources

| Name                                                                                                                                                              | Type        |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [aws_cloudfront_origin_access_control.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control)         | resource    |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)                                        | data source |
| [aws_iam_policy_document.cloudfront_get_public_object_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudfront_log_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)               | data source |
| [aws_iam_policy_document.oac_access_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)               | data source |

## Inputs

| Name                                                                  | Description                                                                                                  | Type       | Default | Required |
|-----------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|------------|---------|:--------:|
| <a name="input_custom_tags"></a> [custom\_tags](#input\_custom\_tags) | Custom tags which can be passed on to the AWS resources. They should be key value pairs having distinct keys | `map(any)` | `{}`    |    no    |
| <a name="input_environment"></a> [environment](#input\_environment)   | Environment Variable used as a prefix                                                                        | `string`   | n/a     |   yes    |
| <a name="input_name"></a> [name](#input\_name)                        | Name of the resource or project                                                                              | `string`   | n/a     |   yes    |
| <a name="input_prefix"></a> [prefix](#input\_prefix)                  | The prefix name of customer to be displayed in AWS console and resource                                      | `string`   | n/a     |   yes    |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
