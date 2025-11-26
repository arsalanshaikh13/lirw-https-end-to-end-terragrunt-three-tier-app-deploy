
 terraform {
    backend "s3" {}
  }



# Creating Application Load balancer
module "alb" {
  source                  = "./modules/alb"
  project_name            = var.project_name
  alb_sg_id               = var.alb_sg_id
  internal_alb_sg_id      = var.internal_alb_sg_id
  pub_sub_1a_id           = var.pub_sub_1a_id
  pub_sub_2b_id           = var.pub_sub_2b_id
  pri_sub_5a_id           = var.pri_sub_5a_id
  pri_sub_6b_id           = var.pri_sub_6b_id
  vpc_id                  = var.vpc_id
  certificate_domain_name = var.certificate_domain_name

}

resource "null_resource" "build_ami" {
  depends_on = [module.alb]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    environment = {
      VPC_ID    = var.vpc_id
      SUBNET_ID = var.pub_sub_1a_id
      # Get RDS details from Terraform state
      DB_HOST                         = var.endpoint_address
      DB_PORT                         = var.db_port
      DB_USER                         = var.db_username
      DB_PASSWORD                     = var.db_password
      DB_NAME                         = var.db_name
      RDS_SG_ID                       = var.db_sg_id
      s3_ssm_cw_instance_profile_name = var.s3_ssm_cw_instance_profile_name
      # db_secret_name                  = module.aws_secret.db_secret_name
      internal_alb_dns_name   = module.alb.internal_alb_dns_name 
      # internal_alb_dns_name   = var.alb_dns_name # for mock purposes using alb dns
      bucket_name             = var.lirw_bucket_name
      aws_region              = var.region
      ANSIBLE_STDOUT_CALLBACK = "yaml"
      packer_directory = var.packer_dir
    }
    # command = "bash ../../packer/packer-script.sh"
    # 👇 Run Ansible playbook instead of shell script
    # command = "ansible-playbook ../../packer/packer-ansible.yml -vv"
    # command = "ansible-playbook ../../packer/packer-ansible.yml -vvvv 2>&1 | tee -a ../../packer/ansible_output.log"
    # on_failure = fail

    # Add explicit error handling in the command
    # command = <<-EOT
    #   {
    #     set -euo pipefail  # Exit on any error
    #     ansible-playbook ../../packer/packer-ansible.yml -vvvv 2>&1 | tee -a ../../packer/ansible_output.log
    #     exit_code=$${PIPESTATUS[0]}
    #     if [ $$exit_code -ne 0 ]; then
    #       echo "❌ Ansible playbook failed with exit code $$exit_code"
    #       exit $$exit_code
    #     fi
    #     echo "✅ Ansible playbook completed successfully"      
    #   }
    # EOT
    command    = "chmod +x null_resource.sh && ./null_resource.sh"
    on_failure = fail
  }

  # # Optional: Add a destroy provisioner to clean up on failure
  # provisioner "local-exec" {
  #   when    = destroy
  #   command = "echo 'Cleaning up failed AMI build resources...'"
  # }
}
#   triggers = {
# ensure re-run when packer template changes
# packer_template_hash = filesha256("../../packer/backend.pkr.hcl")
#   # Change any of these to force rebuild
#   server_build = filemd5("${path.module}/../packer/backend/build_ami.sh")
#   server_script = filemd5("${path.module}/../packer/backend/server.sh")
#   client_build = filemd5("${path.module}/../packer/frontend/build_ami.sh")
#   client_script = filemd5("${path.module}/../packer/frontend/client.sh")
#   # # Or manual trigger
#   # force_rebuild = var.backend_ami_version  # Change this value to rebuild
#   # force_rebuild = var.frontend_ami_version  # Change this value to rebuild
# }


# data "local_file" "packer_manifest_backend" {
#   filename   = "../packer/backend/manifest.json"
#   depends_on = [null_resource.build_ami]
# }

# data "local_file" "packer_manifest_frontend" {
#   filename   = "../packer/frontend/manifest.json"
#   depends_on = [null_resource.build_ami]
# }

# locals {
#   packer_manifest_backend = jsondecode(data.local_file.packer_manifest_backend.content)
#   packer_manifest_frontend = jsondecode(data.local_file.packer_manifest_frontend.content)

#   backend_ami_id  = split(":", local.packer_manifest_backend.builds[0].artifact_id)[1]
#   frontend_ami_id = split(":", local.packer_manifest_frontend.builds[0].artifact_id)[1]
# }


# locals {
#   packer_manifest_backend = jsondecode(file("../packer/backend/manifest.json"))
#   packer_manifest_frontend = jsondecode(file("../packer/frontend/manifest.json"))
#   backend_ami_id  = split(":", local.packer_manifest_backend.builds[0].artifact_id)[1]
#   frontend_ami_id  = split(":", local.packer_manifest_frontend.builds[0].artifact_id)[1]

#   depends_on = [null_resource.build_ami]
# }

# output "backend_ami_id" {
#   value = local.backend_ami_id
# }


module "asg" {
  source                          = "./modules/asg"
  project_name                    = var.project_name
  client_sg_id                    = var.client_sg_id
  server_sg_id                    = var.server_sg_id
  vpc_id                          = var.vpc_id
  vpc_cidr_block                  = var.vpc_cidr_block
  pri_sub_3a_id                   = var.pri_sub_3a_id
  pri_sub_4b_id                   = var.pri_sub_4b_id
  pri_sub_5a_id                   = var.pri_sub_5a_id
  pri_sub_6b_id                   = var.pri_sub_6b_id

  tg_arn                          = module.alb.tg_arn
  internal_tg_arn                 = module.alb.internal_tg_arn
  internal_alb_dns_name = module.alb.internal_alb_dns_name
  # tg_arn                          = var.tg_arn
  # internal_tg_arn                 = var.internal_tg_arn
  # internal_alb_dns_name = var.alb_dns_name

  s3_ssm_cw_instance_profile_name = var.s3_ssm_cw_instance_profile_name
  db_dns_address                  = var.endpoint_address
  db_endpoint                     = var.db_endpoint
  db_username                     = var.db_username
  db_password                     = var.db_password
  db_name                         = var.db_name
  # db_secret_name                  = var.db_secret_name # not required as i am using ssm parameters

  bucket_name           = var.lirw_bucket_name
  region                = var.region
  # backend_ami_id  =  local.backend_ami_id
  # frontend_ami_id  = local.frontend_ami_id
  client_key_name = var.client_key_name
  server_key_name = var.server_key_name
  pri_rt_a_id     = var.pri_rt_a_id
  pri_rt_b_id     = var.pri_rt_b_id
  frontend_ami_file     = var.frontend_ami_file
  backend_ami_file     = var.backend_ami_file
  depends_on      = [module.alb, null_resource.build_ami]

}




