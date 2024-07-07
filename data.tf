data "aws_iam_policy_document" "s3_public_read_policy" {
  statement {
    sid       = "PublicReadGetObject"
    actions   = ["s3:GetObject"]
    effect    = "Allow"
    resources = ["arn:aws:s3:::${aws_s3_bucket.static_web.id}/*"] 

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

data "aws_route53_zone" "selected" {
  name         = "sctp-sandbox.com."
}