output "cloudfront_distribution_arn" {
  description = "The ARN (Amazon Resource Name) for the distribution."
  value       = module.cloudfront_distribution.cloudfront_distribution_arn
}

output "cloudfront_distribution_domain_name" {
  description = "The domain name corresponding to the distribution."
  value       = module.cloudfront_distribution.cloudfront_distribution_domain_name
}

output "cloudfront_origin_access_identities" {
  description = "A pre-generated ARN for use in S3 bucket policies."
  value       = module.cloudfront_distribution.cloudfront_origin_access_identities
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket used as CloudFront origin."
  value       = module.s3_bucket.bucket_name
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket used as CloudFront origin."
  value       = module.s3_bucket.bucket_arn
}

output "s3_bucket_domain_name" {
  description = "The bucket domain name."
  value       = module.s3_bucket.bucket_domain_name
}

output "log_bucket_name" {
  description = "The name of the S3 bucket used for CloudFront logs."
  value       = aws_s3_bucket.cloudfront_log_bucket.id
}

output "log_bucket_arn" {
  description = "The ARN of the S3 bucket used for CloudFront logs."
  value       = aws_s3_bucket.cloudfront_log_bucket.arn
}

output "origin_access_control_id" {
  description = "The ID of the Origin Access Control."
  value       = aws_cloudfront_origin_access_control.this.id
}
