variable "vpc_id" {
  type        = string
  description = "vpc_id variable"
}

variable "environment" {
  type        = string
  description = "environment variable"
}

variable "server_sg_desc" {
  type        = string
  description = "server_sg_desc variable"
}

variable "server_port" {
  type = number
  # default = 3200
  description = "server_port variable"
}

variable "db_sg_desc" {
  type        = string
  description = "db_sg_desc variable"
}

variable "db_inbound_desc" {
  type        = string
  description = "db_inbound_desc variable"
}

variable "db_security_port" {
  type = number
  # default = 3306
  description = "db_security_port variable"
}

