module "vpc" {
  source           = "./vpc"
  aws_region       = "us-west-1"
  vpc_name         = "production"
  vpc_cidr         = "10.0.0.0/16"
  hosted_zone_name = "example.com"
  ssh_pubkey       = "./ssh/aws_ssh.pub"
}

module "node" {
  source          = "./node"
  vpc_name        = "production"
  aws_region      = "us-west-1"
  cluster_size    = "2"
  image_id        = "ami-7b09571b"
  vpc_id          = "${module.vpc.vpc_id}"
  private_subnets = "${module.vpc.private_subnets}"
}

module "bastion" {
  source          = "./bastion"
  name            = "production"
  aws_region      = "us-west-1"
  image_id        = "ami-7d54061d"
  vpc_id          = "${module.vpc.vpc_id}"
  private_subnets = "${module.vpc.private_subnets}"
  public_subnets  = "${module.vpc.public_subnets}"
}
