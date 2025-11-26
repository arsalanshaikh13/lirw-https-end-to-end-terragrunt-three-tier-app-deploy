# Get the certificate from AWS ACM
# data "aws_acm_certificate" "issued" {
#   domain   = var.certificate_domain_name
#   statuses = ["ISSUED"]
# }

#creating Cloudfront distribution :
resource "aws_cloudfront_cache_policy" "caching_optimized" {
  name        = "Caching_optimized"
  comment     = "test comment"
  default_ttl = 50
  max_ttl     = 100
  min_ttl     = 1
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"

    }
    headers_config {
      header_behavior = "none"

    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

resource "aws_cloudfront_origin_request_policy" "only-host-header" {
  name    = "only-host-header"
  comment = "Forwards only the Host header to ALB origin"

  cookies_config {
    cookie_behavior = "all"

  }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["host"]
    }
  }
  query_strings_config {
    query_string_behavior = "none"

  }
}
resource "aws_cloudfront_distribution" "my_distribution" {
  enabled = true
  aliases = [var.additional_domain_name]
  # Add this line to associate WAF
  # web_acl_id = aws_wafv2_web_acl.block_web_acl.arn
  web_acl_id = var.cloudfront_waf_arn
  origin {
    # domain_name = var.alb_domain_name
    domain_name         = var.alb_api_domain_name
    origin_id           = var.alb_api_domain_name
    connection_attempts = 3
    connection_timeout  = 10
    # response_completion_timeout = 30

    custom_origin_config {
      http_port  = 80
      https_port = 443
      # origin_protocol_policy = "http-only"
      # https://www.stormit.cloud/blog/cloudfront-distribution-for-amazon-ec2-alb/
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 30
      origin_keepalive_timeout = 5
    }
    custom_header {
      # name = "X-Custom-Header"
      # value = "random-value-123456"
      name  = var.cloudfront_custom_header_name
      value = var.cloudfront_custom_header_value
    }
  }
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = var.alb_api_domain_name
    viewer_protocol_policy = "redirect-to-https"
    #  Use modern cache behavior config instead of legacy forwarded_values
    cache_policy_id          = aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.only-host-header.id

    # forwarded_values {
    #   # headers      = []
    #   headers      = ["host"]
    #   query_string = true
    #   cookies {
    #     forward = "all"
    #   }
    # }
  }
  restrictions {
    geo_restriction {
      # restriction_type = "whitelist"
      # locations        = ["IN", "US", "CA"]
      restriction_type = "none"

    }
  }
  tags = {
    Name        = "${var.project_name}-cloudfront"
    Environment = var.environment
  }
  viewer_certificate {
    # acm_certificate_arn      = data.aws_acm_certificate.issued.arn
    acm_certificate_arn = var.acm_certificate_arn
    # mock certificate for mock plan
    # acm_certificate_arn   = "arn:aws:iam::187416307283:cf-certificate/test_cert_rab3wuqwgja25ct3n4jdj2323zu4"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }
}


# resource "aws_cloudfront_distribution" "my_distribution" {
#   enabled = true


#   origin {
#     domain_name = var.alb_domain_name
#     origin_id   = var.alb_domain_name

#     custom_origin_config {
#       http_port              = 80
#       https_port              = 443
#       origin_protocol_policy = "http-only"
#       origin_ssl_protocols = ["TLSv1.2"]
#     }
#   }
#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   viewer_certificate {
#       cloudfront_default_certificate = true
#   }
#   default_cache_behavior {
#     allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
#     cached_methods         = ["GET", "HEAD", "OPTIONS"]
#     target_origin_id       = var.alb_domain_name
#     viewer_protocol_policy = "allow-all"
#     forwarded_values {
#       headers      = []
#       query_string = true
#       cookies {
#         forward = "all"
#       }
#     }
#   }

#   tags = {
#     Name = var.project_name
#   }
# }









