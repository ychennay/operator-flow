variable "bastion_ami" {
  # Ubuntu Server 10.08 LTS
  default = "ami-07d0cf3af28718ef8"
}

variable "bastion_ssh_public_key" {}

variable "provider_region" {
  default = "us-east-1"
}

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr_block" {
  default = "10.0.3.0/24"
}

