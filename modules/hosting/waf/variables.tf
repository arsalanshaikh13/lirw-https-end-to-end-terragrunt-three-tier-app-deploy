variable "block_ip_set_name" {
  type        = string
  description = "block_ip_set_name variable"
}

variable "block_ip_set_description" {
  type        = string
  description = "block_ip_set_description variable"
}

variable "block_ipset_scope" {
  type        = string
  description = "block_ipset_scope variable"
}

variable "ip_address_version" {
  type        = string
  description = "ip_address_version variable"
}

variable "ip_addresses" {
  type        = list(string)
  description = "ip_addresses variable"
}

variable "environment" {
  type        = string
  description = "environment variable"
}

variable "cloudfront_waf_name" {
  type        = string
  description = "cloudfront_waf_name variable"
}

variable "cloudfront_waf_description" {
  type        = string
  description = "cloudfront_waf_description variable"
}

variable "cloudfront_waf_scope" {
  type        = string
  description = "cloudfront_waf_scope variable"
}

variable "alb_waf_name" {
  type        = string
  description = "alb_waf_name variable"
}

variable "alb_waf_scope" {
  type        = string
  description = "alb_waf_scope variable"
}

variable "alb_waf_description" {
  type        = string
  description = "alb_waf_description variable"
}

variable "cloudfront_custom_header_value" {
  type        = string
  description = "cloudfront_custom_header_value variable"
}

variable "cloudfront_custom_header_name" {
  type        = string
  description = "cloudfront_custom_header_name variable"
}

variable "public_alb_arn" {
  type        = string
  description = "ARN of ALB (load balancer listener or ALB) to associate with WAF"
}
# variable "cloudfront_arn" {
#   type        = string
#   description = "ARN of Cloudfront to associate with WAF"
# }
variable "project_name" {
  type        = string
  description = "project_name variable"
}


