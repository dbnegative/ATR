variable "aws_region" {
  description = "AWS EC2 Region for VPC"
  default     = "us-east-1"
}

variable "hosted_zone_name" {
  type        = "string"
  description = "Name of hosted zone"
  default     = "example.com"
}

variable "ssh_pubkey" {
  type        = "string"
  description = "Path to the SSH public key"
  default     = "./ssh/aws_ssh.pub"
}
