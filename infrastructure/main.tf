variable "provider_region" {
  default   = "us-east-1"
}

variable "cidr_block" {
    default = "10.0.0.0/16"
}


provider "aws" {
    region = var.provider_region
}

resource "aws_vpc" "operator_flow_vpc" {
    cidr_block                  = var.cidr_block
    enable_dns_hostnames        = true

}