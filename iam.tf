resource "aws_iam_role" "main" {
  name = "${var.base_name}-cloudfront-logs-access-role"
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

  tags = merge({
    Name = "${var.base_name}-cloudfront-logs-access-role"
  }, var.custom_tags)
}

resource "aws_iam_role_policy" "main" {
  name = "${var.base_name}-cloudfront-logs-access-policy"
  role = aws_iam_role.main.id

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
