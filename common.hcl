# https://www.youtube.com/watch?v=K-usNxyEETE&list=PL6YlWHeZL6SxXN_wNX2ZdkH40_iEf_SLq&index=18 - malek karemi nejad 
# - be-devops terraform and terragrunt series

locals {

  config_hcl          = read_terragrunt_config("${get_repo_root()}/configuration/config.hcl")
  region              = local.config_hcl.locals.region
  backend_bucket_name = local.config_hcl.locals.backend_bucket_name
  dynamodb_table      = local.config_hcl.locals.dynamodb_table
  provider_version = local.config_hcl.locals.provider_version
}

#  Automatically generate provider.tf for all subfolders
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
    backend  "s3"{
    bucket         = "${local.backend_bucket_name}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "${local.region}"
    dynamodb_table = "${local.dynamodb_table}"
    encrypt        = true
    use_lockfile   = true
  }
}
EOF
}
# Automatically generate provider.tf for all subfolders
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = "${local.provider_version["terraform"]}"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "${local.provider_version["aws"]}"
    }
  }
}

provider "aws" {
  region = "${local.region}"
}
EOF
}

generate "debug" {
  path      = "debug_outputs.txt"
  if_exists = "overwrite"
  contents  = <<EOF
  terragrunt_dir: ${get_terragrunt_dir()}

original_terragrunt_dir: ${get_original_terragrunt_dir()}

get_repo_root: ${get_repo_root()}

get_parent_terragrunt_dir: ${get_parent_terragrunt_dir()}

EOF
}
# get_working_dir: ${get_working_dir()}

