module "vpc" {
  source           = "./vpc"
  aws_region       = "us-west-1"
  vpc_name         = "production"
  vpc_cidr         = "10.0.0.0/16"
  aws_azs          = ["c", "b"]
  hosted_zone_name = "example.com"
  ssh_pubkey       = "./ssh/aws_ssh.pub"
}

module "rancher-mgmt" {
  source               = "./rancher-mgmt"
  vpc_name             = "production"
  aws_region           = "us-west-1"
  cluster_size         = "2"
  image_id             = "ami-7b09571b"
  vpc_id               = "${module.vpc.vpc_id}"
  vpc_cidr             = "10.0.0.0/16"
  aws_azs              = ["us-west-1c", "us-west-1b"]
  private_subnets      = "${module.vpc.private_subnets}"
  public_subnets       = "${module.vpc.public_subnets}"
  root_dbusername      = "rancheradmin"
  root_dbpassword      = "rancheradmin"
  dbname               = "rancherdb"
  hosted_zone_id       = "Z6Z290XNPS459A"
  domain               = "example.com"
  domain_email_address = "you@example.com"
}

module "bastion" {
  source          = "./bastion"
  name            = "production"
  aws_region      = "us-west-1"
  image_id        = "ami-7d54061d"
  vpc_id          = "${module.vpc.vpc_id}"
  private_subnets = "${module.vpc.private_subnets}"
  public_subnets  = "${module.vpc.public_subnets}"
  hosted_zone_id  = "Z6Z290XNPS459A"
  domain          = "example.com"
}
