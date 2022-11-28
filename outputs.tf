output "cloudfront_distribution_domain_name" {
  description = "The domain name corresponding to the distribution. For example: d604721fxaaqy9.cloudfront.net"
  value       = aws_cloudfront_distribution.distribution.domain_name
}

output "cloudfront_origin_access_identities" {
  description = "A pre-generated ARN for use in S3 bucket policies (see below). Example: arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E2QWRUHAPOMQZL."
  value       = { for k, v in aws_cloudfront_origin_access_identity.this : k => v if var.origin_access_identities != {} }
}
