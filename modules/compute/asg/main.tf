# data "local_file" "frontend_ami" {
#   # filename = "${path.module}/ami_ids/frontend_ami.txt"
#   # filename = "${get_terragrunt_dir()}/modules/ami_ids/frontend_ami.txt"
#   # filename = "../../../modules/ami_ids/frontend_ami.txt"
#   filename = var.frontend_ami_file
#   # filename = "/mnt/c/Users/DELL/ArsVSCode/CS50p_project/project_aFinal/website/"website 2.0"/animations/scroll/aws_three_tier_arch/lirw-three-tier/folder-based-project/terraform/compute/modules/ami_ids/frontend_ami.txt"
#   # filename = "get_original_terragrunt_dir()/modules/ami_ids/frontend_ami.txt"
# }

# data "local_file" "backend_ami" {
#   # filename = "${path.module}/ami_ids/backend_ami.txt"
#   # filename = "${get_terragrunt_dir()}/modules/ami_ids/backend_ami.txt"
#   # filename = "../../../modules/ami_ids/backend_ami.txt"
#   filename = var.backend_ami_file
#   # filename = "/mnt/c/Users/DELL/ArsVSCode/CS50p_project/project_aFinal/website/'website 2.0'/animations/scroll/aws_three_tier_arch/lirw-three-tier/folder-based-project/terraform/compute/modules/ami_ids/backend_ami.txt"

# }
# locals {
#   # web = "website2_0"
#   # frontend_ami_file = "/mnt/c/Users/DELL/ArsVSCode/CS50p_project/project_aFinal/website/${local.web}/animations/scroll/aws_three_tier_arch/lirw-three-tier/folder-based-project/terraform/compute/modules/ami_ids/frontend_ami.txt"
#   # backend_ami_file = "/mnt/c/Users/DELL/ArsVSCode/CS50p_project/project_aFinal/website/${local.web}/animations/scroll/aws_three_tier_arch/lirw-three-tier/folder-based-project/terraform/compute/modules/ami_ids/backend_ami.txt"

#   frontend_ami_id = trimspace(data.local_file.frontend_ami.content)
#   backend_ami_id  = trimspace(data.local_file.backend_ami.content)
#   # frontend_ami_id = trimspace(local.frontend_ami_file)
#   # backend_ami_id  = trimspace(local.backend_ami_file)
# #   frontend_ami_id = trimspace(var.frontend_ami_file)
# #   backend_ami_id  = trimspace(var.backend_ami_file)
# }

resource "aws_launch_template" "lt_name" {
  name = "${var.project_name}-tpl"
  # image_id      = data.aws_ami.latest_amazon_linux.id
  # image_id      = local.frontend_ami_id
  # image_id      = "ami-08203b7a67f23af2c"
  image_id      = var.frontend_ami_id
  instance_type = var.frontend_instance_type
  key_name      = var.client_key_name
  # user_data     = filebase64("../modules/asg/client.sh")

  # using packer
  # user_data = base64encode(templatefile("${path.module}/client.sh", {
  #   internal_alb_dns_name = var.internal_alb_dns_name
  #   bucket_name = var.bucket_name
  # }))
  # backend_alb_dns = var.internal_alb_dns_name


  # vpc_security_group_ids = [var.client_sg_id]

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.client_sg_id]
  }
  iam_instance_profile {
    # name = var.s3_ssm_instance_profile_name
    name = var.s3_ssm_cw_instance_profile_name
  }

  lifecycle {
    # ignore_changes = [image_id]
    create_before_destroy = false
  }
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      # volume_type = "standard"
      volume_type           = var.frontend_volume_type
      delete_on_termination = true
      # volume_size = 8
      volume_size = var.frontend_volume_size
      encrypted   = true
    }
  }
  # propagate tag on the instance launched from this template
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-client"
    }
  }
  tags = {
    Name        = "${var.project_name}-tpl"
    Environment = var.environment
  }
}
# terraform apply -target=module.asg.aws_launch_template.server_lt_name
resource "aws_launch_template" "server_lt_name" {
  name = "${var.project_name}-server_tpl"
  # image_id      = data.aws_ami.latest_amazon_linux.id
  # image_id      = local.backend_ami_id
  image_id      = var.backend_ami_id
  instance_type = var.backend_instance_type
  key_name      = var.server_key_name
  # user_data     = filebase64("../modules/asg/server.sh")
  # depends_on = [ aws_s3_object.DbConfig ]

  # vpc_security_group_ids = [var.server_sg_id]

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.server_sg_id]
  }

  # using packer
  #  user_data = base64encode(templatefile("${path.module}/server.sh", {
  #     db_host     = var.db_dns_address
  #     db_username = var.db_username
  #     db_password = var.db_password
  #     db_name     = var.db_name
  #     db_secret_name     = var.db_secret_name
  #     bucket_name = var.bucket_name
  #     aws_region = var.region
  #   }))
  iam_instance_profile {
    # name = var.s3_ssm_instance_profile_name
    name = var.s3_ssm_cw_instance_profile_name
  }

  lifecycle {
    # ignore_changes = [image_id]
    create_before_destroy = false
  }
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      # volume_type = "standard"
      volume_type           = var.backend_volume_type
      delete_on_termination = true
      # volume_size = 8
      volume_size = var.backend_volume_size
      encrypted   = true
    }
  }

  # propagate tag on the instance launched from this template
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-server"
    }
  }
  tags = {
    Name        = "${var.project_name}-server_tpl"
    Environment = var.environment
  }
}

resource "aws_autoscaling_group" "asg_name" {
  name                      = "${var.project_name}-asg"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_cap
  health_check_grace_period = 300
  health_check_type         = var.asg_health_check_type #"ELB" or default EC2
  vpc_zone_identifier       = [var.pri_sub_3a_id, var.pri_sub_4b_id]
  target_group_arns         = [var.tg_arn] 

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  launch_template {
    id      = aws_launch_template.lt_name.id
    version = "$Latest"
    # version = aws_launch_template.lt_name.latest_version 
  }
  tag {
    key                 = "Name"
    value               = "${var.project_name}-client-ec2"
    propagate_at_launch = true
  }

}
resource "aws_autoscaling_group" "server_asg_name" {

  name                      = "${var.project_name}-server-asg"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_cap
  health_check_grace_period = 300
  health_check_type         = var.asg_health_check_type #"ELB" or default EC2
  vpc_zone_identifier       = [var.pri_sub_5a_id, var.pri_sub_6b_id]
  target_group_arns         = [var.internal_tg_arn] #var.target_group_arns

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  launch_template {
    id      = aws_launch_template.server_lt_name.id
    version = "$Latest"

    # version = aws_launch_template.server_lt_name.latest_version 
  }
  tag {
    key                 = "Name"
    value               = "${var.project_name}-server-ec2"
    propagate_at_launch = true
  }

}
