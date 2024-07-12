data "aws_iam_policy_document" "s3_cloudfront_access" {
  statement {
    sid       = "PublicReadGetObject"
    actions   = ["s3:GetObject"]
    effect    = "Allow"
    resources = ["arn:aws:s3:::${aws_s3_bucket.static_web.id}/*"] 

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["${aws_cloudfront_distribution.s3_distribution.arn}"]
    }
  }
}

data "aws_route53_zone" "selected" {
  name         = "sctp-sandbox.com."
}

data "aws_cloudfront_cache_policy" "example" {
  name = "Managed-CachingOptimized"
}

data "aws_acm_certificate" "name" {
  provider = aws.us-east-1 #Syntax: <provider>.<alias>
  domain   = "sctp-sandbox.com"
}