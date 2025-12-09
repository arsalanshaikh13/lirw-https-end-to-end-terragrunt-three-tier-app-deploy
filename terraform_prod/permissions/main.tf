
terraform {
    backend "s3" {}
}

module "iam_role" {
  source = "./modules/iam_role"
  vpc_id = var.vpc_id
  region = var.region
}


# module "nat_instance" {
#   source = "./modules/nat_instance"

#   pub_sub_1a_id  = var.pub_sub_1a_id
#   pub_sub_2b_id  = var.pub_sub_2b_id
#   pri_sub_3a_id  = var.pri_sub_3a_id
#   pri_sub_4b_id  = var.pri_sub_4b_id
#   pri_sub_5a_id  = var.pri_sub_5a_id
#   pri_sub_6b_id  = var.pri_sub_6b_id
#   igw_id         = var.igw_id
#   vpc_id         = var.vpc_id
#   vpc_cidr_block = var.vpc_cidr_block
#   s3_ssm_cw_instance_profile_name = module.iam_role.s3_ssm_cw_instance_profile_name
#   nat_bastion_key_name =  module.key.nat_bastion_key_name
# pri_rt_a_id = var.pri_rt_a_id
# pri_rt_b_id = var.pri_rt_b_id

#   depends_on                      = [ module.iam_role] # Wait for VPC before DB
# }

module "acm" {
  source = "./modules/acm"
}



# creating Key for instances
module "key" {
  source = "./modules/key"
}

