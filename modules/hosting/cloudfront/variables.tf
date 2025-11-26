variable "certificate_domain_name" {
  type        = string
  description = "certificate_domain_name variable"
}

variable "additional_domain_name" {
  type        = string
  description = "additional_domain_name variable"
}

variable "cloudfront_waf_arn" {
  type        = string
  default     = null
  description = "cloudfront_waf_arn variable"
}

variable "alb_api_domain_name" {
  type        = string
  description = "alb_api_domain_name variable"
}

variable "cloudfront_custom_header_name" {
  type        = string
  description = "cloudfront_custom_header_name variable"
}

variable "cloudfront_custom_header_value" {
  type        = string
  description = "cloudfront_custom_header_value variable"
}

variable "project_name" {
  type        = string
  description = "project_name variable"
}

variable "environment" {
  type        = string
  description = "environment variable"
}

variable "acm_certificate_arn" {
  type        = string
  description = "acm_certificate_arn variable"
}

