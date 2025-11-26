# Setting up WAF 
resource "aws_wafv2_ip_set" "block_ipset" {
  name               = var.block_ip_set_name
  description        = var.block_ip_set_description
  scope              = var.block_ipset_scope
  ip_address_version = var.ip_address_version
  addresses          = var.ip_addresses
  tags = {
    Environment = var.environment
    Name        = var.block_ip_set_name
  }
}

resource "aws_wafv2_web_acl" "block_web_acl" {
  name        = var.cloudfront_waf_name
  description = var.cloudfront_waf_description
  scope       = var.cloudfront_waf_scope # Must match the IP Set's scope
  default_action {
    allow {}
  }
  rule {
    name     = "block-ip-set-rule"
    priority = 1
    action {
      # block {}
      captcha {
        # not supported yet this block captcha_config
        # captcha_config {
        #   immunity_time_property = 300
        # }
      }
      # captcha {
      #   custom_request_handling {
      #     insert_header {
      #       name  = "X-Custom-Header"
      #       value = "random-value-123456"
      #     }
      #   }
    }
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.block_ipset.arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "block-ip-set-rule"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "block-bad-useragents"
    priority = 3

    action {
      block {}
    }

    statement {
      byte_match_statement {
        search_string = "curl"
        field_to_match {
          single_header { name = "user-agent" }
        }
        text_transformation {
          priority = 0
          type     = "NONE"
        }
        positional_constraint = "CONTAINS"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "block-bad-useragents"
    }
  }

  rule {
    name     = "block-empty-useragent"
    priority = 4

    action {
      block {}
    }

    # statement {
    #   not_statement {
    #     statement {
    #       byte_match_statement {
    #         # search_string         = ""
    #         search_string         = "a"
    #         field_to_match {
    #           single_header { name = "user-agent" }
    #         }
    #         text_transformation { 
    #           priority = 0 
    #           type = "NONE" 
    #         }
    #         positional_constraint = "EXACTLY"
    #       }
    #     }
    #   }
    # }

    statement {
      size_constraint_statement {
        field_to_match {
          single_header { name = "user-agent" }
        }
        comparison_operator = "LT"
        size                = 1
        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "block-empty-useragent"
    }
  }

  rule {
    name     = "limit-ip-rate"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 100 # requests in 5 mins
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "limit-ip-rate"
    }
  }


  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "not-block-ip-set"
    sampled_requests_enabled   = true
  }
  # ... other rules and settings as needed
  tags = {
    # Environment = "dev"
    Name        = "${var.project_name}-cloudfront-waf"
    Environment = var.environment
  }

}

# log web acl config
# resource "aws_wafv2_web_acl_logging_configuration" "cloudfront_waf_logs" {
#   resource_arn            = aws_wafv2_web_acl.block_web_acl.arn
#   log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf_logs.arn]
# }
# CloudFront WAF always uses us-east-1
# provider "aws" {
#   alias  = "us_east_1"
#   region = "us-east-1"
# }
# resource "aws_wafv2_web_acl_association" "example_association" {
#   # provider     = aws.us_east_1
#   resource_arn = aws_cloudfront_distribution.my_distribution.arn # Replace with your ALB or CloudFront ARN
#   web_acl_arn  = aws_wafv2_web_acl.block_web_acl.arn
# }



# Web ACL (REGIONAL for ALB)
resource "aws_wafv2_web_acl" "alb_acl" {
  name        = var.alb_waf_name
  scope       = var.alb_waf_scope
  description = var.alb_waf_description

  default_action {
    block {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.alb_waf_name}-metrics"
    sampled_requests_enabled   = true
  }

  ########################################
  # 1) ALLOW rule: CloudFront header validation (check first)
  ########################################
  rule {
    name     = "allow-cloudfront-header"
    priority = 1

    action {
      allow {}
    }

    statement {
      byte_match_statement {
        search_string         = var.cloudfront_custom_header_value
        positional_constraint = "EXACTLY"

        field_to_match {
          single_header {
            name = lower(var.cloudfront_custom_header_name)
          }
        }

        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allow-cloudfront-header"
      sampled_requests_enabled   = true
    }
  }

  ########################################
  # 2) BLOCK rule: simple SQL injection
  ########################################
  rule {
    name     = "block-simple-sqli"
    priority = 10

    action {
      block {}
    }
    # multiple statements using OR statements
    # statement {
    #   or_statement {
    #     statement {
    #       sqli_match_statement {
    #         field_to_match {
    #           query_string {}
    #         }
    #         text_transformation {
    #           priority = 0
    #           type     = "URL_DECODE"
    #         }
    #         text_transformation {
    #           priority = 1
    #           type     = "LOWERCASE"
    #         }
    #       }
    #     }

    #     statement {
    #       sqli_match_statement {
    #         field_to_match {
    #           body {}
    #         }
    #         text_transformation {
    #           priority = 0
    #           type     = "URL_DECODE"
    #         }
    #         text_transformation {
    #           priority = 1
    #           type     = "LOWERCASE"
    #         }
    #       }
    #     }
    #   }
    # }


    # Just single statement without or statment for body
    statement {
      sqli_match_statement {
        field_to_match {
          query_string {}
        }
        text_transformation {
          priority = 0
          type     = "URL_DECODE"
        }
        text_transformation {
          priority = 1
          type     = "LOWERCASE"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "block-simple-sqli"
      sampled_requests_enabled   = true
    }
  }

  ########################################
  # 3) BLOCK rule: simple XSS
  ########################################
  rule {
    name     = "block-simple-xss"
    priority = 11

    action {
      block {}
    }

    # multiple statements using OR statements
    # statement {
    #   or_statement {
    #     statement {
    #       xss_match_statement {
    #         field_to_match {
    #           query_string {}
    #         }
    #         text_transformation {
    #           priority = 0
    #           type     = "URL_DECODE"
    #         }
    #         text_transformation {
    #           priority = 1
    #           type     = "HTML_ENTITY_DECODE"
    #         }
    #         text_transformation {
    #           priority = 2
    #           type     = "LOWERCASE"
    #         }
    #       }
    #     }

    #     statement {
    #       xss_match_statement {
    #         field_to_match {
    #           body {}
    #         }
    #         text_transformation {
    #           priority = 0
    #           type     = "URL_DECODE"
    #         }
    #         text_transformation {
    #           priority = 1
    #           type     = "HTML_ENTITY_DECODE"
    #         }
    #         text_transformation {
    #           priority = 2
    #           type     = "LOWERCASE"
    #         }
    #       }
    #     }

    #     statement {
    #       xss_match_statement {
    #         field_to_match {
    #           uri_path {}
    #         }
    #         text_transformation {
    #           priority = 0
    #           type     = "URL_DECODE"
    #         }
    #         text_transformation {
    #           priority = 1
    #           type     = "HTML_ENTITY_DECODE"
    #         }
    #       }
    #     }
    #   }
    # }

    # Just single statement without OR statment for body
    statement {
      xss_match_statement {
        field_to_match {
          query_string {}
        }
        text_transformation {
          priority = 0
          type     = "URL_DECODE"
        }
        text_transformation {
          priority = 1
          type     = "HTML_ENTITY_DECODE"
        }
        text_transformation {
          priority = 2
          type     = "LOWERCASE"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "block-simple-xss"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    # Environment = "dev"
    Environment = var.environment
    Name        = "${var.project_name}-alb-waf"

  }
}

# Associate with ALB
resource "aws_wafv2_web_acl_association" "alb_assoc" {
  resource_arn = var.public_alb_arn
  web_acl_arn  = aws_wafv2_web_acl.alb_acl.arn
}
# terraform documentation doesn't allow for this and instead forces to use web_acl_id attribute in cloudfront resource
# to detach waf from cloudfront set web_acl_id = null by setting cloudfront_waf_arn to null by default in variables.tf in cloudfront module
# resource "aws_wafv2_web_acl_association" "cloudfront_assoc" {
#   resource_arn = var.cloudfront_arn
#   web_acl_arn = aws_wafv2_web_acl.block_web_acl.arn
# }








