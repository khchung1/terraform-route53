resource "aws_s3_bucket" "static_web" {
  bucket = "kokhui-staticwebsite.sctp-sandbox.com"
}

resource "aws_s3_bucket_public_access_block" "static_web_resource" {
  bucket = aws_s3_bucket.static_web.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "static_web_bucket" {
  bucket = aws_s3_bucket.static_web.id
  policy = data.aws_iam_policy_document.s3_public_read_policy.json
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
    origin_id                = aws_s3_bucket.static_web.id
  }

  enabled             = true
  is_ipv6_enabled     = false
  comment             = "Kok Hui CloudFront Follow-up"
  default_root_object = "index.html"



  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.static_web.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.static_web.id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.static_web.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["SG"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

