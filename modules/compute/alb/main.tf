# create application load balancer
resource "aws_lb" "application_load_balancer" {
  name                       = "${var.project_name}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_sg_id]
  subnets                    = [var.pub_sub_1a_id, var.pub_sub_2b_id]
  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = var.environment

  }
}

# create target group
resource "aws_lb_target_group" "alb_target_group" {
  name        = "${var.project_name}-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    interval            = 300
    path                = "/health"
    timeout             = 60
    matcher             = 200
    healthy_threshold   = 2
    unhealthy_threshold = 5
    port                = "traffic-port"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# data "aws_acm_certificate" "issued" {
#   domain   = var.certificate_domain_name
#   statuses = ["ISSUED"]
# }

resource "aws_lb_listener" "http-redirect" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  tags = {
    Name        = "redirect-to-https"
    Environment = var.environment
  }
}
# create a listener on port 80 with redirect action
resource "aws_lb_listener" "alb_http_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  # port              = 80
  # protocol          = "HTTP"
  # https://www.stormit.cloud/blog/cloudfront-distribution-for-amazon-ec2-alb/
  port       = 443
  protocol   = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  # for mock purposes using mock arns
  # certificate_arn   = data.aws_acm_certificate.issued.arn
  certificate_arn   = var.acm_certificate_arn
  # mock certificate for mock plan
  # certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"


  # default_action {
  #   type = "forward"
  #   target_group_arn = aws_lb_target_group.alb_target_group.arn
  # }

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied"
      status_code  = "403"
    }
  }
}
# for extra certificate extra domain names only and not primary domain names
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate
# resource "aws_lb_listener_certificate" "example" {
#   listener_arn = aws_lb_listener.alb_http_listener.arn
#   # certificate_arn = data.aws_acm_certificate.issued.arn
#   certificate_arn = var.acm_certificate_arn
# }

resource "aws_lb_listener_rule" "forward-custom-http-header" {
  listener_arn = aws_lb_listener.alb_http_listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }

  condition {
    http_header {
      # http_header_name = "X-Custom-Header"
      # values           = ["random-value-123456"]
      http_header_name = var.cloudfront_custom_header_name
      values           = [var.cloudfront_custom_header_value]
    }
  }
  tags = {
    Name        = "allow-access-to-custom-header-only"
    Environment = var.environment
  }

}

# resource "aws_lb_listener_rule" "deny-access" {
#   listener_arn = aws_lb_listener.alb_http_listener.arn
#   priority = last

#   action {
#     type = "fixed-response"

#     fixed_response {
#       content_type = "text/plain"
#       message_body = "Access Denied"
#       status_code  = "403"
#     }
#   }
#   condition {
#     http_header {
#       any source other than this http_header is to be denied
#       http_header_name = "X-Custom-Header"
#       values           = ["random-value-123456"]
#     }
#   }
# }

# create Internal application load balancer
resource "aws_lb" "internal_application_load_balancer" {
  name                       = "${var.project_name}-internal-alb"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [var.internal_alb_sg_id]
  subnets                    = [var.pri_sub_5a_id, var.pri_sub_6b_id]
  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-internal-alb"
    Environment = var.environment

  }
}

# create internal alb target group
resource "aws_lb_target_group" "internal_alb_target_group" {
  name        = "${var.project_name}-internal-tg"
  target_type = "instance"
  # port        = 3200
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    interval            = 300
    path                = "/health"
    timeout             = 60
    matcher             = 200
    healthy_threshold   = 2
    unhealthy_threshold = 5
    port                = "traffic-port"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# create a listener on port 80 with redirect action
resource "aws_lb_listener" "internal_alb_http_listener" {
  load_balancer_arn = aws_lb.internal_application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_alb_target_group.arn
  }
}

