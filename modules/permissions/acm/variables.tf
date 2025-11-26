variable "certificate_domain_name" {
  type        = string
  description = "certificate_domain_name variable"
  #   default = "devsandbox.space"
}
variable "environment" {
  type        = string
  description = "environment variable"
}
variable "acm_validation_method" {
  type        = string
  description = "acm_validation_method variable"
}

variable "additional_domain_name" {
  type        = string
  description = "additional_domain_name variable"
}

variable "alb_api_domain_name" {
  type        = string
  description = "alb_api_domain_name variable"
}

