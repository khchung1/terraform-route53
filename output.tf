output "zone_id"{

    value = aws_s3_bucket.static_web.hosted_zone_id
}

output "website_domain" {
    value = aws_s3_bucket_website_configuration.static_web_config.website_domain
}


output "dns_zone_id"{
    value = data.aws_route53_zone.selected.zone_id  
}