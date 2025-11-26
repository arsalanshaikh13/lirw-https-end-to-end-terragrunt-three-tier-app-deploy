variable "certificate_domain_name" {
  type        = string
  description = "certificate_domain_name variable"
  # default = "devsandbox.space"

}

variable "cloudfront_domain_name" {
  type        = string
  description = "cloudfront_domain_name variable"
}

variable "cloudfront_hosted_zone_id" {
  type        = string
  description = "cloudfront_hosted_zone_id variable"
}

variable "cloudfront_distro_aliases" {
  type        = list(string)
  description = "cloudfront_distro_aliases variable"
}

variable "alb_api_domain_name" {
  type        = string
  description = "alb_api_domain_name variable"
}
variable "public_alb_dns_name" {
  type        = string
  description = "public_alb_dns_name variable"
}

variable "public_alb_zone_id" {
  type        = string
  description = "public_alb_zone_id variable"
}

