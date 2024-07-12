resource "aws_s3_bucket" "static_web" {
  bucket = "kokhui-staticwebsite.sctp-sandbox.com"
}

# resource "aws_s3_bucket_public_access_block" "static_web_resource" {
#   bucket = aws_s3_bucket.static_web.id

#   block_public_acls       = false
#   block_public_policy     = false
#   ignore_public_acls      = false
#   restrict_public_buckets = false
# }

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = aws_s3_bucket.static_web.id
  policy = data.aws_iam_policy_document.s3_cloudfront_access.json
}

resource "aws_s3_bucket_website_configuration" "static_web_config" {
  bucket = aws_s3_bucket.static_web.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_route53_record" "www" {
  zone_id =  data.aws_route53_zone.selected.zone_id          #Zone ID of hosted zone: sctp-sandbox.com
  name    = "kokhui-staticwebsite"                  # Bucket name prefix, before your domain
  type    = "A"

  alias {
    name  =  aws_s3_bucket_website_configuration.static_web_config.website_domain  #S3 website configuration attribute: website_domain
    zone_id = aws_s3_bucket.static_web.hosted_zone_id # Hosted zone of the S3 bucket, Attribute:hosted_zone_id
    evaluate_target_health = true
  }
}


resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = "kokhui-staticwebsite.sctp-sandbox.com.s3.ap-southeast-1.amazonaws.com"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = aws_s3_bucket.static_web.id
  }

  enabled             = true
  is_ipv6_enabled     = false
  comment             = "Kok Hui CloudFront Follow-up w OAC"
  default_root_object = "index.html"



  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.static_web.id
    cache_policy_id  = data.aws_cloudfront_cache_policy.example.id
    viewer_protocol_policy = "allow-all"

  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.name.arn
    ssl_support_method  = "sni-only"
  }
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "OAC for Website"
  description                       = "OAC for S3 Static Website using CloudFront"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}



