# DNS Mapping
resource "aws_route53_record" "application" {
  count   = var.is_automatic_create_dns_record ? 1 : 0
  zone_id = data.aws_route53_zone.hosted_zone.id
  name    = var.acm_cert_domain_name
  type    = "A"

  alias {
    name                   = lower(aws_cloudfront_distribution.distribution.domain_name)
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = true
  }
}
