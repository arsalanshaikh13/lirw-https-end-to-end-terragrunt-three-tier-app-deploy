 terraform {
    backend "s3" {}
  }


# creating RDS instance
module "rds" {
  source        = "./modules/rds"
  db_sg_id      = var.db_sg_id
  pri_sub_7a_id = var.pri_sub_7a_id
  pri_sub_8b_id = var.pri_sub_8b_id
  db_username   = var.db_username
  db_password   = var.db_password
}

module "aws_ssm_param" {
  source         = "./modules/aws_ssm_param"
  db_dns_address = module.rds.endpoint_address
  db_username    = var.db_username
  db_password    = var.db_password
  db_name        = var.db_name
  project_name   = var.project_name
  depends_on     = [module.rds] # Wait for VPC before DB

}
