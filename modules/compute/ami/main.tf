resource "null_resource" "build_ami" {

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    environment = {
      VPC_ID    = var.vpc_id
      SUBNET_ID = var.pub_sub_1a_id
      # Get RDS details from Terraform state
      DB_HOST                         = var.db_dns_address
      DB_PORT                         = var.db_port
      DB_USER                         = var.db_username
      DB_PASSWORD                     = var.db_password
      DB_NAME                         = var.db_name
      DB_PORT                         = var.db_port
      RDS_SG_ID                       = var.db_sg_id
      s3_ssm_cw_instance_profile_name = var.s3_ssm_cw_instance_profile_name
      internal_alb_dns_name           = var.internal_alb_dns_name
      bucket_name                     = var.lirw_bucket_name
      aws_region                      = var.region
      ssh_interface                   = var.ssh_interface
      ssh_username                    = var.ssh_username
      backend_ami_type                = var.backend_ami_type
      backend_instance_type           = var.backend_instance_type
      backend_volume_type             = var.backend_volume_type
      backend_volume_size             = var.backend_volume_size
      backend_ami_name                = var.backend_ami_name
      frontend_ami_type               = var.frontend_ami_type
      frontend_instance_type          = var.frontend_instance_type
      frontend_volume_type            = var.frontend_volume_type
      frontend_volume_size            = var.frontend_volume_size
      frontend_ami_name               = var.frontend_ami_name
      environment                     = var.environment
      packer_folder                   = var.packer_folder
      ANSIBLE_CALLBACK_RESULT_FORMAT  = "yaml"
      ANSIBLE_LOAD_CALLBACK_PLUGINS   = 1
      ANSIBLE_STDOUT_CALLBACK         = "minimal" 
    }

    command    = "chmod +x null_resource.sh && ./null_resource.sh"
    on_failure = fail

    # command = "bash ../packer/packer-script.sh"
    # command = "bash ${var.packer_folder}/packer-script.sh"
    # command = var.packer_folder

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
    # command    = "chmod +x null_resource.sh && ./null_resource.sh"
    # on_failure = fail
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

data "local_file" "packer_manifest_backend" {
  # filename   = "../packer/backend/manifest.json"
  filename   = "${var.packer_folder}/backend/manifest.json"
  depends_on = [null_resource.build_ami]
}

data "local_file" "packer_manifest_frontend" {
  # filename   = "../packer/frontend/manifest.json"
  filename   = "${var.packer_folder}/frontend/manifest.json"
  depends_on = [null_resource.build_ami]
}

locals {
  packer_manifest_backend  = jsondecode(data.local_file.packer_manifest_backend.content)
  packer_manifest_frontend = jsondecode(data.local_file.packer_manifest_frontend.content)

  backend_ami_id  = split(":", local.packer_manifest_backend.builds[0].artifact_id)[1]
  frontend_ami_id = split(":", local.packer_manifest_frontend.builds[0].artifact_id)[1]
}



