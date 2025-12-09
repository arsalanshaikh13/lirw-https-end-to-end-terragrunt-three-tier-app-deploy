

include "root" {
  path = find_in_parent_folders("common.hcl")
  expose = true
}
include "global_mocks" {
  path   = find_in_parent_folders("global-mocks.hcl")
  expose = true
}
locals {
  region           = include.root.locals.region
  provider_version = include.root.locals.provider_version

}

terraform {
  # source = "../../../../modules/app"
  # source = "${path_relative_from_include("root")}/modules/hosting/waf"
  source = "tfr://gitlab.com/arsalanshaikh13/tf-modules-lirw-packer/aws//hosting/waf?version=1.0.1-waf-region"

  # You can also specify multiple extra arguments for each use case. Here we configure terragrunt to always pass in the
  # `common.tfvars` var file located by the parent terragrunt config.
  extra_arguments "custom_vars" {
    commands = [
      "apply",
      "plan",
      "destroy"
    ]

    # required_var_files = ["terraform.tfvars"]
    # required_var_files = ["${path_relative_from_include("root")}/configuration/dev/us-east-1/app/app.tfvars"]
    # required_var_files = ["${path_relative_from_include("root")}/configuration/${basename(dirname(dirname(get_terragrunt_dir())))}/${basename(dirname(get_terragrunt_dir()))}/${basename(get_terragrunt_dir())}/app.tfvars"]
    # required_var_files = ["${path_relative_from_include("root")}/configuration/terraform.tfvars"]
    #     required_var_files = ["${dirname(dirname(dirname(get_terragrunt_dir())))}/configuration/terraform.tfvars"]
    # https://terragrunt.gruntwork.io/docs/reference/hcl/functions/#get_parent_terragrunt_dir
#     required_var_files = ["${get_parent_terragrunt_dir("root")}/configuration/terraform.tfvars"]
#       required_var_files = ["${get_parent_terragrunt_dir("root")}/configuration/dev/terraform.tfvars"]
      required_var_files = ["${get_parent_terragrunt_dir("root")}/configuration/prod/terraform.tfvars"]
  }


  before_hook "pre_fmt" {
    commands = ["plan"]
    execute  = ["bash", "-c", "echo 'Running terraform format'; terraform fmt --recursive"]
  }
  before_hook "pre_validate" {
    commands = ["plan"]
    execute  = ["bash", "-c", "echo 'Running terraform validate'; terraform validate"]
  }

  before_hook "tflint" {
    commands = ["plan"]
    execute = [
      "bash", "-c",
      <<-EOT
        tflint --recursive --minimum-failure-severity=error --config "${get_terragrunt_dir()}/custom.tflint.hcl"
        exit_code=$?
        echo "exit code : $exit_code"
        exit $exit_code
      EOT
    ]
  }
  after_hook "post_apply_graph" {
    commands = ["apply"]
    execute  = ["bash", "-c", "echo 'Running terraform graph'; mkdir -p '${get_terragrunt_dir()}'/graph; terraform graph > '${get_terragrunt_dir()}'/graph/graph-apply.dot"]
  }
  after_hook "post_apply_message" {
    commands = ["apply"]
    execute  = ["bash", "-c", "echo '✅ Resources created successfully'"]
  }

  error_hook "Display ERROR" {
    commands = ["plan", "apply", "destroy"]
    execute  = ["echo", "Error occured while running the operation!!!"]
    on_errors = [
      ".*",
    ]
  }


  after_hook "post_destroy" {
    commands = ["destroy"]
    execute  = ["bash", "-c", "echo '✅ Resources deleted successfully'"]
  }
}

# dependency "cloudfront" {
#   # config_path                             = "../cloudfront"
#   config_path                             = "${dirname(get_terragrunt_dir())}/cloudfront"
#   mock_outputs                            = include.global_mocks.locals.global_mock_outputs
#   mock_outputs_allowed_terraform_commands = ["plan"]
# }
dependency "alb" {
  # config_path                             = "../../permissions/alb"
  config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/compute/alb"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]

}

# # Generate extended provider block (adds local & null)
generate "provider_waf" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
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

# Default provider for us-east-2 (ALB cert and other resources)
provider "aws" {
  region = "${local.region}"
}

# Aliased provider for us-east-1 (CloudFront cert only)
provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"
}
EOF
}

inputs = {
  # cloudfront_arn = dependency.cloudfront.outputs.cloudfront_arn
  public_alb_arn = dependency.alb.outputs.public_alb_arn

}
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --  plan 
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --  apply -auto-approve
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --working-dir network -- destroy -auto-approve
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --working-dir app --   destroy -auto-approve
