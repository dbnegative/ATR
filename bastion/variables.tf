variable "aws_region" {
  description = "AWS EC2 Region for VPC"
}

variable "image_id" {
  type        = "string"
  description = "Image ID"
}

variable "private_subnets" {
  type        = "list"
  description = "Internal subnet IDs"
}

variable "public_subnets" {
  type        = "list"
  description = "External subnet IDs"
}

variable "vpc_id" {
  type        = "string"
  description = "VPC ID"
}

variable "name" {
  type        = "string"
  description = "Name of the Environment"
}
