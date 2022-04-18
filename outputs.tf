output "cf_domain_name" {
  value = "${aws_cloudfront_distribution.distribution.domain_name}"
}

output "cf_s3_iam_arn" {
  value = "${aws_cloudfront_origin_access_identity.cloudfront_s3_policy.iam_arn}"
}