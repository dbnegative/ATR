module "vpc" {
  source       = "./vpc"
  aws_region   = "${var.aws_region}"
  aws_vpc_name = "my_terraform_vpc"
  vpc_cidr     = "10.0.0.0/16"
}
