locals {
  region              = "us-east-1"
  environment         = "dev"
  backend_bucket_name = "lirw-backend"
  dynamodb_table      = "lirw-lock-table"

  # terraform_required_version      = "~> 1.13.3"
  # aws_provider_version      = "4.67.0"
  # local_provider_version      = "~> 2.4"
  provider_version = {
    terraform     = "~> 1.13.3"
    aws           = "4.67.0"
    local         = "~> 2.4"
    null_provider = "~> 3.2"
    tls           = "~> 4.0"

  }
}