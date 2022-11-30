resource "aws_iam_role" "main" {
  count = var.is_create_log_access_role ? 1 : 0

  name = "${local.name}-cloudfront-logs-access-role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "*"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(local.tags, { "Name" : local.name })
}

resource "aws_iam_role_policy" "main" {
  count = var.is_create_log_access_role ? 1 : 0

  name = "${local.name}-cloudfront-logs-access-policy"
  role = aws_iam_role.main[0].id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
         "s3:GetBucketAcl",
         "s3:PutBucketAcl"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.log_aggregation_s3_bucket_name}"
    }
  ]
}
EOF

}
