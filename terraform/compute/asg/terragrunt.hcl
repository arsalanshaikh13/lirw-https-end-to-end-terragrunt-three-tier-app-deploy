

include "root" {
  path   = find_in_parent_folders("common.hcl")
  expose = true
}
include "global_mocks" {
  path   = find_in_parent_folders("global-mocks.hcl")
  expose = true
}
locals {
  region = include.root.locals.region
  # aws_provider_version = include.root.locals.aws_provider_version
  # local_provider_version = include.root.locals.local_provider_version
  provider_version = include.root.locals.provider_version
}

terraform {
  # source = "../../../../modules/app"
  source = "${path_relative_from_include("root")}/modules/compute/asg"

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
    required_var_files = ["${get_parent_terragrunt_dir("root")}/configuration/terraform.tfvars"]
  }

  # The following are examples of how to specify hooks
  # https://terragrunt.gruntwork.io/docs/features/hooks/

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

# Generate extended provider block (adds local & null)
generate "provider_compute" {
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
    local = {
      source  = "hashicorp/local"
      version = "${local.provider_version["local"]}"
    }
  }
}
provider "aws" {
  region = "${local.region}"
}

EOF
}


dependency "vpc" {
  # config_path                             = "../../network/vpc"
  config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/network/vpc"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}

dependency "sg" {
  config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/network/sg"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}

dependency "rds" {
  # config_path                             = "../../database/rds"
  config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/database/rds"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}

dependency "iam_role" {
  config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/permissions/iam_role"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}

dependency "alb" {
  # config_path                             = "../alb"
  config_path                             = "${dirname(get_terragrunt_dir())}/alb"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}
dependency "ami" {
  # config_path                             = "../ami"
  config_path                             = "${dirname(get_terragrunt_dir())}/ami"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}

dependency "s3" {
  # config_path                             = "../../s3"
  config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/s3"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}
dependency "key" {
  # config_path                             = "../../nat_key/key"
  config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/nat_key/key"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}

inputs = {
  project_name                    = dependency.vpc.outputs.project_name
  pri_sub_3a_id                   = dependency.vpc.outputs.pri_sub_3a_id
  pri_sub_4b_id                   = dependency.vpc.outputs.pri_sub_4b_id
  pri_sub_5a_id                   = dependency.vpc.outputs.pri_sub_5a_id
  pri_sub_6b_id                   = dependency.vpc.outputs.pri_sub_6b_id
  client_sg_id                    = dependency.sg.outputs.client_sg_id
  server_sg_id                    = dependency.sg.outputs.server_sg_id
  tg_arn                          = dependency.alb.outputs.tg_arn
  internal_tg_arn                 = dependency.alb.outputs.internal_tg_arn
  internal_alb_dns_name           = dependency.alb.outputs.internal_alb_dns_name
  s3_ssm_cw_instance_profile_name = dependency.iam_role.outputs.s3_ssm_cw_instance_profile_name
  db_dns_address                  = dependency.rds.outputs.db_dns_address
  db_endpoint                     = dependency.rds.outputs.db_endpoint
  bucket_name                     = dependency.s3.outputs.lirw_bucket_name
  frontend_ami_id                 = dependency.ami.outputs.frontend_ami_id
  backend_ami_id                  = dependency.ami.outputs.backend_ami_id
  client_key_name                 = dependency.key.outputs.client_key_name
  server_key_name                 = dependency.key.outputs.server_key_name

}
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --  plan 
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --  apply -auto-approve
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --working-dir network -- destroy -auto-approve
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --working-dir app --   destroy -auto-approve
