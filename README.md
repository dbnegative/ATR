# AWS Rancher Terraform Bootstrap
Creates a multi AZ HA rancher enviroment in AWS using Terraform. Split into modules for ease of use. 

# Requirements:
 - Terraform v0.9 >
 - ACME plugin for Terraform, to generate Lets Encrypt certs: https://github.com/paybyphone/terraform-provider-acme 
 
# Usage:
 - Update main.tf with your prefered settings

# Currently builds:
 - VPC
 - Internet gateway
 - 1 x public subnet per AZ 
 - 1 x private subnet per AZ
 - 1 x NAT gateway per private subnet
 - Routing tables
 - Bastion host in public subnet with ELB
 - RDS (mysql) for Rancher HA backened
 - Auto scaling group rancher management nodes
 - IAM policies and security groups
 - Rancher management nodes split over each AZ
 - ELB with let's encrypt SSL cert
 - Route 53 records for bastion and Rancher web interface

# Complete:
 - Rancher Web Interface Nodes
 - Mysql RDS HA Backend
 - Bastion host
 - ELB for Rancher web managment nodes
 - IAM roles for nodes
 - SSL certs for web nodes ELB's
 - ELB proxy policy for web managment nodes

# Things to add (Work in Progress):
 - Rancher default username and access control
 - Worker nodes
 - Worker nodes ASG
 - Worker nodes registration 
 - S3
 - Better ELB health checks

