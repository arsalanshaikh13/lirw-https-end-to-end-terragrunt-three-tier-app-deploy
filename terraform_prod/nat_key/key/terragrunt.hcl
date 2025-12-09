

include "root" {
  path   = find_in_parent_folders("common.hcl")
  expose = true

}
include "global_mocks" {
  path   = find_in_parent_folders("global-mocks.hcl")
  expose = true
}

locals {
  # key_folder        = "${get_parent_terragrunt_dir("root")}/modules/nat_key/key"
  # client_key = "${local.ami_folder}/frontend_ami.txt"
  # server_k  = "${local.ami_folder}/backend_ami.txt"
  # packer_folder     = "${get_parent_terragrunt_dir("root")}/packer"
  # frontend_manifest = "${local.packer_folder}/frontend/manifest.json"
  # backend_manifest  = "${local.packer_folder}/backend/manifest.json"
  region           = include.root.locals.region
  provider_version = include.root.locals.provider_version

}


terraform {
  # source = "../../../../modules/app"
  # source = "${path_relative_from_include("root")}/modules/nat_key/key"
  source = "tfr://gitlab.com/arsalanshaikh13/tf-modules-lirw-packer/aws//nat_key/key?version=1.0.0-lirw-packer"

  # You can also specify multiple extra arguments for each use case. Here we configure terragrunt to always pass in the
  # `common.tfvars` var file located by the parent terragrunt config.
  extra_arguments "custom_vars" {
    commands = [
      "apply",
      "plan",
      "destroy"
    ]

    # required_var_files = ["terraform.tfvars"]
    # required_var_files = ["${get_parent_terragrunt_dir()}/configuration/dev/us-east-1/app/app.tfvars"]
    # required_var_files = ["${get_parent_terragrunt_dir()}/configuration/${basename(dirname(dirname(get_terragrunt_dir())))}/${basename(dirname(get_terragrunt_dir()))}/${basename(get_terragrunt_dir())}/app.tfvars"]
    # required_var_files = ["${get_parent_terragrunt_dir()}/configuration/terraform.tfvars"]
    # required_var_files = ["${path_relative_from_include("root")}/configuration/terraform.tfvars"]
    #     required_var_files = ["${dirname(dirname(dirname(get_terragrunt_dir())))}/configuration/terraform.tfvars"]
    # https://terragrunt.gruntwork.io/docs/reference/hcl/functions/#get_parent_terragrunt_dir
#     required_var_files = ["${get_parent_terragrunt_dir("root")}/configuration/terraform.tfvars"]
#       required_var_files = ["${get_parent_terragrunt_dir("root")}/configuration/dev/terraform.tfvars"]
      required_var_files = ["${get_parent_terragrunt_dir("root")}/configuration/prod/terraform.tfvars"]
  }

  # The following are examples of how to specify hooks


  # Before apply, run "echo Bar". Note that blocks are ordered, so this hook will run after the previous hook to
  # "echo Foo". In this case, always "echo Bar" even if the previous hook failed.
  before_hook "pre_fmt" {
    commands = ["plan"]
    execute  = ["bash", "-c", "echo 'Running terraform format'; terraform fmt --recursive"]
  }
  # before_hook "check_for_ssh_keys" {
  #   commands = ["plan"]
  #   # execute  = ["bash", "-c", "./key.sh '${get_parent_terragrunt_dir("root")}/modules/nat_key/key'"]
  #   execute = ["bash", "-c", "./key.sh ${local.key_folder}"]
  # }
  
  before_hook "pre_validate" {
    commands = ["plan"]
    execute  = ["bash", "-c", "echo 'Running terraform validate'; terraform validate"]
  }

  after_hook "delete_keys" {
    commands = ["destroy"]
    execute = [
      "bash", "-c",
      <<-EOT
        echo "Deleting SSH keys from ${get_original_terragrunt_dir()} folder"
        cd "${get_original_terragrunt_dir()}"
        rm -f *.pem
      EOT
    ]
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

  # after_hook "post_apply_find" {
  #   commands = ["apply"]
  #   execute = [
  #     "bash", "-c",
  #     <<-EOT
  #       DEST="${get_original_terragrunt_dir()}"
  #       echo "dest: $DEST"
        
  #       find . -type f -name '*.pem' -print0 |
  #       xargs -0 -I{} sh -c 'echo $1 && chmod 400 $1 && cp $1 $2' _ {} $DEST
  #     EOT
  #   ]
  # }

  after_hook "post_apply_find" {
    commands = ["apply"]
    execute = [
      "bash", "-c",
      <<-EOT
        DEST="${get_original_terragrunt_dir()}"
        echo "Destination: $DEST"

        find . -type f -name '*.pem' -print0 |
        xargs -0 -I{} sh -c '
          src="$1"
          dest_dir="$2"
          filename="$(basename "$src")"
          dest_file="$dest_dir/$filename"

          if [ -f "$dest_file" ]; then
            echo "Skipping (exists): $dest_file"
            exit 0
          fi

          echo "Copying: $src -> $dest_file"
          chmod 400 "$src"
          cp "$src" "$dest_file"
        ' _ "{}" "$DEST"
      EOT
    ]
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
  if_exists = "overwrite_terragrunt"
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
    tls = {
      source  = "hashicorp/tls"
      version = "${local.provider_version["tls"]}"
    }
  }
}
provider "aws" {
  region = "${local.region}"
}

EOF
}



# dependency "backend" {
#   config_path                             = "${get_repo_root()}/backend-tfstate-bootstrap"
#   mock_outputs                            = { vpc_id = "vpc-3a1234abcd5678ef" }
#   mock_outputs_allowed_terraform_commands = ["plan"]
# }
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --  plan 
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --  apply -auto-approve
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --working-dir network -- destroy -auto-approve
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --working-dir app --   destroy -auto-approve

# SOURCE="network"
#  echo 'vpc security-group iam_role'  | tr ' ' '\n'  | xargs -I {} mv {}  "$SOURCE" ;

# delete same folder/file from each directory
# find . -type f -name ".terraform.lock.hcl" -prune -exec rm -rf {} \;

# copy same folder in to many different folders
# SOURCE_FOLDER="network/security-group"
# echo "s3 rds aws_secret alb asg null_resource asg cloudfront route53" | tr ' ' '\n'  | xargs -I {} cp -r "$SOURCE_FOLDER" {};
