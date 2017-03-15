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

variable "image_id" {
  description = "AMI ID"
}
