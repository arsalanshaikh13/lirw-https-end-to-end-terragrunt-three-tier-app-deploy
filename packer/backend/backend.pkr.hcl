# packer.pkr.hcl
# Backend AMI: PHP + Apache + MySQL client

# -----------------------
# Variables
# -----------------------
variable "aws_region" {
  type = string
  # default     = "us-east-1"
  description = "AWS region to build the AMI in."
}

variable "source_ami" {
  type        = string
  default     = ""
  description = "Base AMI to use as the source image (set via -var or a var-file)."
}

variable "backend_instance_type" {
  type = string
  # default     = "t4g.micro"
  # https://aws.amazon.com/ec2/instance-types/t4/
  # default     = "t4g.small"
  description = "EC2 instance type to use for the temporary build instance."
}

variable "ssh_username" {
  type = string
  # default     = "ec2-user"
  description = "SSH user for the temporary build instance."
}
variable "ssh_interface" {
  type = string
  # default     = "session_manager"
  description = "SSH interface for the temporary build instance."
}

variable "vpc_id" {
  type        = string
  default     = ""
  description = "VPC id where the build instance will be launched."
}

variable "subnet_id" {
  type        = string
  default     = ""
  description = "Subnet id where the build instance will be launched."
}

variable "security_group_id" {
  type        = string
  default     = ""
  description = "Security group id attached to the build instance (single SG)."
}

variable "rds_sg_id" {
  type        = string
  default     = ""
  description = "(Unused in template) RDS security group id — kept for consistency if you want to reference it elsewhere."
}

variable "db_host" {
  type        = string
  default     = ""
  description = "Database host endpoint used by mysql client to run the schema/import step."
}

variable "db_port" {
  type = string
  # default     = "3306"
  description = "Database port (string to match original)."
}
variable "db_name" {
  type        = string
  default     = ""
  description = "Database Name"
}

variable "db_user" {
  type        = string
  default     = ""
  description = "DB user that has privileges to run the SQL in database_setup.sql."
}

variable "db_password" {
  type        = string
  default     = ""
  description = "DB password. Avoid committing secrets to source; use -var or a var-file."
  sensitive   = true
}
variable "s3_ssm_cw_instance_profile_name" {
  type        = string
  default     = ""
  description = "Instance profile for packer for ssm s3 and cw"
}
variable "db_secret_name" {
  type        = string
  default     = ""
  description = "secret to access from aws secret manager"
}
variable "bucket_name" {
  type        = string
  default     = ""
  description = "s3  bucket name"
}
variable "volume_type" {
  type        = string
  default     = ""
  description = "volume type of instance"
}
variable "volume_size" {
  type        = number
  description = "volume storage size"
}
variable "environment_stage" {
  type        = string
  default     = ""
  description = "environment - dev, prod, staging"
}
variable "backend_ami_name" {
  type        = string
  default     = ""
  description = "backend ami name"
}
variable "server_key_name" {
  type        = string
  default     = ""
  description = "server key pair name"
}

variable "key_file_path" {
  type = string
  # default     = "../../terraform/permissions/modules/key/server_key"
  description = " key file path"
}


locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

# i am already searching for latest amazon ami in build_ami.sh
# data "amazon-ami" "example" {
#   filters = {
#     virtualization-type = "hvm"
#     name                = "al2023-ami-2023.*-arm64"
#     root-device-type    = "ebs"
#   }
#   owners      = ["amazon"]
#   most_recent = true
#   region      = "us-east-1"
# }
# -----------------------
# Source (amazon-ebs builder)
# -----------------------
source "amazon-ebs" "backend" {
  region     = var.aws_region
  source_ami = var.source_ami
  # source_ami                  = data.amazon-ami.example.id
  instance_type               = var.backend_instance_type
  vpc_id                      = var.vpc_id
  subnet_id                   = var.subnet_id
  security_group_id           = var.security_group_id
  associate_public_ip_address = true
  ssh_username                = var.ssh_username
  temporary_key_pair_name     = "packer-${local.timestamp}"
  ssh_timeout                 = "6m"
  ssh_handshake_attempts      = 30
  communicator                = "ssh"
  ssh_pty                     = true
  # ssh_interface               = "public_ip"
  # ssh_interface = "session_manager"
  ssh_interface        = var.ssh_interface
  ssh_keypair_name     = var.server_key_name
  ssh_private_key_file = var.key_file_path


  iam_instance_profile = var.s3_ssm_cw_instance_profile_name


  ami_name        = "${var.backend_ami_name}-${local.timestamp}"
  ami_description = "Backend AMI with NodeJS, MySQL client, and CloudWatch agent"

  tags = {
    Component   = "backend"
    Environment = var.environment_stage
    Name        = var.backend_ami_name
  }

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    encrypted             = true
    volume_type           = var.volume_type
    volume_size           = var.volume_size
    delete_on_termination = true
  }
}

# -----------------------
# Build (connects source -> provisioners -> post-processors)
# -----------------------
build {
  sources = ["source.amazon-ebs.backend"]


  # # Step 1: Install Ansible
  # provisioner "shell" {
  #   inline = [
  #     "echo 'Installing Ansible on EC2 builder instance...'",
  #     "sudo yum update -y",
  #     "sudo yum install -y ansible ",
  #     # "sudo yum install -y python3-pip",
  #     # "sudo pip3 install ansible --break-system-packages || sudo yum install -y ansible",
  #     "ansible --version"
  #   ]
  # }

  # Combined Python check and install
  provisioner "shell" {
    inline = [
      "#!/bin/bash",
      "set -euo pipefail",
      "",
      "echo '🔍 Checking and installing Python3 if needed...'",
      "",
      "# Check Python3",
      "if command -v python3 &> /dev/null; then",
      "  echo '✅ Python3 already installed'",
      "  python3 --version",
      "else",
      "  echo '📦 Installing Python3...'",
      "  sudo yum update -y",
      "  sudo yum install -y python3 python3-pip",
      "fi",
      "",
      "# Verify pip3",
      "if ! command -v pip3 &> /dev/null; then",
      "  echo '📦 Installing pip3...'",
      "  sudo yum install -y python3-pip",
      "fi",
      "",
      "# Final verification",
      "echo '✅ Final verification:'",
      "python3 --version",
      "pip3 --version",
      "which python3"
    ]
  }

  provisioner "ansible" {
    # playbook_file    = "/tmp/server-ansible.yml"
    playbook_file = "./server-ansible.yml"
    user          = var.ssh_username
    timeout       = "5m"
    # extra_arguments  = [
    #   "-vvvv",
    #   "--extra-vars",
    #   "ansible_python_interpreter=/usr/bin/python3 
    #           bucket_name=${var.bucket_name} db_host=${var.db_host} 
    #           db_username=${var.db_user} db_password=${var.db_password} 
    #           db_name=${var.db_name} aws_region=${var.aws_region} 
    #           ssh_username=${var.ssh_username}",
    # ]

    extra_arguments = [
      "-vvvv",
      "--extra-vars",
      jsonencode({
        ansible_python_interpreter = "/usr/bin/python3"
        bucket_name                = var.bucket_name
        db_host                    = var.db_host
        db_username                = var.db_user
        db_password                = var.db_password
        db_name                    = var.db_name
        aws_region                 = var.aws_region
        environment_stage          = var.environment_stage
        ssh_username               = var.ssh_username
      })
    ]
    ansible_env_vars = ["ANSIBLE_FORCE_COLOR=true", "ANSIBLE_STDOUT_CALLBACK=minimal", "ANSIBLE_CALLBACK_RESULT_FORMAT=yaml", "ANSIBLE_LOAD_CALLBACK_PLUGINS=1"]

  }

  # the provisioner to run on error to cleanup resources
  # error-cleanup-provisioner "shell-local" {
  #   inline = ["echo 'rubber ducky'> ducky.txt"]
  # }

  post-processor "manifest" {
    output = "manifest-${var.environment_stage}.json"
  }
}
