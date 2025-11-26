
# -------- Variables --------
variable "aws_region" {
  type = string
  # default     = "us-east-1"
  description = "AWS region where the AMI will be built."
}

variable "source_ami" {
  type        = string
  default     = ""
  description = "Base AMI id to use as the source image (set via -var or environment)."
}

variable "frontend_instance_type" {
  type = string
  # default = "t4g.micro"
  # default = "t4g.small"
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
  type    = string
  default = ""
}

variable "subnet_id" {
  type    = string
  default = ""
}
variable "s3_ssm_cw_instance_profile_name" {
  type        = string
  default     = ""
  description = "Instance profile for packer for ssm s3 and cw"
}
variable "bucket_name" {
  type        = string
  default     = ""
  description = "s3  bucket name"
}
variable "internal_alb_dns_name" {
  type        = string
  default     = ""
  description = "alb dns to alter "
}
variable "volume_type" {
  type        = string
  default     = ""
  description = "volume type of instance"
}
variable "volume_size" {
  type = number
  # default     = ""
  description = "volume storage size"
}
variable "environment" {
  type        = string
  default     = ""
  description = "environment - dev, prod, staging"
}
variable "frontend_ami_name" {
  type        = string
  default     = ""
  description = "frontend ami name"
}
variable "client_key_name" {
  type        = string
  default     = ""
  description = "client key pair name"
}
variable "key_file_path" {
  type = string
  # default     = "../../terraform/permissions/modules/key/client_key"
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
# -------- Source (amazon-ebs builder) --------
source "amazon-ebs" "frontend" {
  region     = var.aws_region
  source_ami = var.source_ami
  # source_ami                  = data.amazon-ami.example.id
  instance_type               = var.frontend_instance_type
  vpc_id                      = var.vpc_id
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  temporary_key_pair_name     = "packer-${local.timestamp}"
  ssh_username                = var.ssh_username
  # ssh_interface                 = "public_ip"
  ssh_timeout            = "10m"
  ssh_handshake_attempts = 30
  communicator           = "ssh"
  ssh_pty                = true
  # ssh_interface        = "session_manager"
  ssh_interface        = var.ssh_interface
  ssh_keypair_name     = var.client_key_name
  ssh_private_key_file = var.key_file_path

  iam_instance_profile = var.s3_ssm_cw_instance_profile_name

  ami_name        = "${var.frontend_ami_name}-${local.timestamp}"
  ami_description = "Frontend AMI with Nginx and Git and react"
  tags = {
    Name        = var.frontend_ami_name
    Environment = var.environment
    Component   = "frontend"
  }

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    encrypted             = true
    volume_type           = var.volume_type
    volume_size           = var.volume_size
    delete_on_termination = true
  }


}

# -------- Build (ties source -> provisioners -> post-processors) --------
build {
  sources = ["source.amazon-ebs.frontend"]


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


  # Run Ansible playbook instead of shell script
  provisioner "ansible" {
    playbook_file = "./client-ansible.yml"
    user          = var.ssh_username
    timeout       = "5m"
    # variables passed into Ansible
    # extra_arguments = [
    #   "-vvvv",
    #   "--extra-vars", 
    #   "ansible_python_interpreter=/usr/bin/python3 bucket_name=${var.bucket_name} internal_alb_dns_name=${var.internal_alb_dns_name}"
    # ]
    extra_arguments = [
      "-vvvv",
      "--extra-vars",
      jsonencode({
        ansible_python_interpreter = "/usr/bin/python3"
        bucket_name                = var.bucket_name
        internal_alb_dns_name      = var.internal_alb_dns_name
        ssh_username               = var.ssh_username
      })
    ]
    # Optional verbosity (remove if you prefer)
    ansible_env_vars = ["ANSIBLE_FORCE_COLOR=true", "ANSIBLE_STDOUT_CALLBACK=yaml", "ANSIBLE_LOAD_CALLBACK_PLUGINS=1"]
  }

  # the provisioner to run on error to cleanup resources
  # error-cleanup-provisioner "shell-local" {
  #   inline = ["echo 'rubber ducky'> ducky.txt"]
  # }
  post-processor "manifest" {
    output = "manifest.json"
  }
}
