variable "project_name" {
  type        = string
  description = "project_name variable"
}

variable "alb_sg_id" {
  type        = string
  description = "alb_sg_id variable"
}

variable "pub_sub_1a_id" {
  type        = string
  description = "pub_sub_1a_id variable"
}

variable "pub_sub_2b_id" {
  type        = string
  description = "pub_sub_2b_id variable"
}

variable "environment" {
  type        = string
  description = "environment variable"
}

variable "vpc_id" {
  type        = string
  description = "vpc_id variable"
}

variable "acm_certificate_arn" {
  type        = string
  description = "acm_certificate_arn variable"
}

variable "internal_alb_sg_id" {
  type        = string
  description = "internal_alb_sg_id variable"
}

variable "pri_sub_5a_id" {
  type        = string
  description = "pri_sub_5a_id variable"
}

variable "pri_sub_6b_id" {
  type        = string
  description = "pri_sub_6b_id variable"
}

variable "server_port" {
  type        = number
  description = "server_port variable"
}

variable "cloudfront_custom_header_name" {
  type        = string
  description = "cloudfront_custom_header_name variable"
}

variable "cloudfront_custom_header_value" {
  type        = string
  description = "cloudfront_custom_header_value variable"
}

