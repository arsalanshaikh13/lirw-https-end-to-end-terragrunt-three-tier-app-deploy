 terraform {
    backend "s3" {}
  }

# create cloudfront distribution 
module "cloudfront" {
  source                  = "./modules/cloudfront"
  certificate_domain_name = var.certificate_domain_name
  # alb_domain_name         = module.alb.alb_dns_name
  alb_api_domain_name    = var.alb_api_domain_name
  additional_domain_name = var.additional_domain_name
  project_name           = var.project_name
  public_alb_arn         = var.public_alb_arn

}

# Add record in route 53 hosted zone

module "route53" {
  source                    = "./modules/route53"
  cloudfront_domain_name    = module.cloudfront.cloudfront_domain_name
  cloudfront_distro_aliases = module.cloudfront.cloudfront_aliases
  cloudfront_hosted_zone_id = module.cloudfront.cloudfront_hosted_zone_id
  public_alb_dns_name       = var.alb_dns_name
  public_alb_zone_id        = var.alb_zone_id
  hosted_zone_name          = var.certificate_domain_name
}


