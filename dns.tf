# DNS Mapping
resource "aws_route53_record" "application" {
  for_each = var.is_automatic_create_dns_record ? local.aliases_records : {}
  zone_id  = data.aws_route53_zone.hosted_zone[0].id
  name     = each.value.name
  type     = "A"

  alias {
    name                   = lower(aws_cloudfront_distribution.distribution.domain_name)
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = true
  }
}
