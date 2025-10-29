module "route53" {
  source             = "../modules/r53"
  alb_dns_name       = module.alb.alb_dns_name
  alb_hosted_zone_id = module.alb.alb_hosted_zone_id
  sub_domain         = var.sub_domain
  hosted_zone_name   = var.hosted_zone_name
}



module "network" {
  source             = "../modules/network"
  region             = var.region
  module_prefix      = var.project_name
  vpc_cidr           = var.vpc_cidr
  pub_sub_a_cidr     = var.pub_sub_a_cidr
  pub_sub_b_cidr     = var.pub_sub_b_cidr
  jenkins_sub_a_cidr = var.pub_sub_jenkins_a_cidr
}

module "security-group" {
  source                     = "../modules/security-group"
  module_prefix              = var.project_name
  vpc_id                     = module.network.vpc_id
  jenkins_allowed_http_cidrs = var.jenkins_allowed_http_cidrs
}



module "s3" {
  source = "../modules/s3"
  name   = var.bucket_name
}



module "instance-profiles" {
  source        = "../modules/iam-instance-profile"
  module_prefix = var.project_name
  s3_bucket_arn = module.s3.arn
}

module "jenkins-ec2" {
  source               = "../modules/ec2"
  module_prefix        = var.project_name
  vpc_id               = module.network.vpc_id
  subnet_id            = module.network.jenkins_sub_a_id
  sg_id                = module.security-group.pipeline_agent_sg_id
  ami_id               = data.aws_ami.amazon_linux.id
  iam_instance_profile = module.instance-profiles.jenkins_ec2_instance_profile_name
  // user_data                     = file("${path.module}/user-data-scripts/simple-apache.sh")
}

module "alb" {
  source        = "../modules/alb"
  module_prefix = var.project_name
  alb_sg_id     = module.security-group.alb_sg_id
  pub_sub_a_id  = module.network.pub_sub_a_id
  pub_sub_b_id  = module.network.pub_sub_b_id
  vpc_id        = module.network.vpc_id
}

module "asg" {
  source                        = "../modules/asg"
  module_prefix                 = var.project_name
  sg_id                         = module.security-group.web_sg_id
  sub_a_id                      = module.network.pub_sub_a_id
  sub_b_id                      = module.network.pub_sub_b_id
  tg_arn                        = module.alb.tg_arn
  ami_id                        = data.aws_ami.amazon_linux.id
  asg_health_check_grace_period = 300
  iam_instance_profile          = module.instance-profiles.app_ec2_instance_profile_arn
  user_data                     = filebase64("${path.module}/user-data-scripts/nginx-deploy.sh")
}
