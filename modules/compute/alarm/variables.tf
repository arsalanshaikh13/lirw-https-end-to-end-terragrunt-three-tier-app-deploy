variable "email_address" {
  type        = list(string)
  description = "List of email addresses to receive email alert"
  #   default     = ["ars786sh@gmail.com"]
}
variable "project_name" {
  type        = string
  description = "project_name variable"
}

variable "client_asg_name" {
  type        = string
  description = "client_asg_name variable"
}

variable "server_asg_name" {
  type        = string
  description = "server_asg_name variable"
}

