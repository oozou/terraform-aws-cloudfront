module "acm_virginia" {
  source = "git::ssh://git@github.com/oozou/terraform-aws-acm.git?ref=v1.0.1"
  providers = {
    aws = aws.virginia
  }
  acms_domain_name  = ["*.example.com"]
  route53_zone_name = "example.com"
}
