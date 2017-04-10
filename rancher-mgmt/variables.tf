variable "vpc_name" {
  description = "AWS VPC Name"
}

variable "cluster_size" {
  description = "Cluster size"
}

variable "aws_region" {
  description = "AWS EC2 Region for VPC"
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "private_subnets" {
  description = "List of private subnets"
  type        = "list"
}

variable "public_subnets" {
  description = "List of private subnets"
  type        = "list"
}

variable "image_id" {
  description = "AMI ID"
}

variable "aws_azs" {
  description = "List of AWS Availabilty Zones"
  type        = "list"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
}

variable "hosted_zone_id" {
  description = "Hosted Zone ID of Main Domain"
}

variable "domain" {
  description = "Rancher Domain"
}

variable "domain_email_address" {
  description = "Lets Encrypt registered domain email address"
}

variable "dbname" {
  description = "Rancher MYSQL RDS DB name"
}

variable "root_dbusername" {
  description = "Root MYSQL RDS Username"
}

variable "root_dbpassword" {
  description = "Root MYSQL RDS Password"
}
