terraform {
  backend "s3" {}
}
module "vpc" {
  source          = "./modules/vpc"
  region          = var.region
  project_name    = var.project_name
  vpc_cidr        = var.vpc_cidr
  pub_sub_1a_cidr = var.pub_sub_1a_cidr
  pub_sub_2b_cidr = var.pub_sub_2b_cidr
  pri_sub_3a_cidr = var.pri_sub_3a_cidr
  pri_sub_4b_cidr = var.pri_sub_4b_cidr
  pri_sub_5a_cidr = var.pri_sub_5a_cidr
  pri_sub_6b_cidr = var.pri_sub_6b_cidr
  pri_sub_7a_cidr = var.pri_sub_7a_cidr
  pri_sub_8b_cidr = var.pri_sub_8b_cidr
}



module "security-group" {
  source     = "./modules/security-group"
  vpc_id     = module.vpc.vpc_id
  depends_on = [module.vpc] # Wait for VPC before DB
}

# module "nat" {
#   source = "./modules/nat"

#   pub_sub_1a_id = module.vpc.pub_sub_1a_id
#   igw_id        = module.vpc.igw_id
#   pub_sub_2b_id = module.vpc.pub_sub_2b_id
#   vpc_id        = module.vpc.vpc_id
#   pri_sub_3a_id = module.vpc.pri_sub_3a_id
#   pri_sub_4b_id = module.vpc.pri_sub_4b_id
#   pri_sub_5a_id = module.vpc.pri_sub_5a_id
#   pri_sub_6b_id = module.vpc.pri_sub_6b_id
# pri_rt_a_id = module.vpc.pri_rt_a_id
# pri_rt_b_id = module.vpc.pri_rt_b_id

# }

# creating s3 bucket to keep application files
module "s3" {
  source      = "./modules/s3"
  bucket_name = var.bucket_name
  upload_folder = var.upload_folder
}
