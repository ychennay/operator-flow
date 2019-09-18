# Backend Infrastructure

## Overview

This repository contains infrastructure code to set up KubeFlow on AWS EKS (Elastic Kubernetes Service). 
It requires several dependencies:

* an appropriate `awscli` profile configured using the public/private access keys
* a Databricks account provisioned, along with an active API key that must be generated via the Databricks UI.

## Modules

### Databricks

Databricks requires a special VPC set up for its clusters to run inside. The IAM role 


## Terraform

Terraform is used to provision many of the underlying infrastructure, including the

* core OperatorFlow VPC
* bastion host EC2 instance
* route tables and subnet CIDR blocks
* Databricks subnet
* IAM (Identity Access Management) roles for Databricks to provision Apache Spark EC2 instances
* S3 buckets to store Databricks metadata

### Steps to Replicate

1. Make sure you are in the `infrastructure/` folder.
2. Run `terraform init` to initialize Terraform locally.
3. Run `terraform plan` to fetch remote state from AWS and compare against the local Terraform state.
4. Run `terraform apply` to apply the changes and create the necessary infrastructure. 

### Bastion Host

OperatorFlow's infrastructure is provisioned via a **bastion host** that is set up in its own separate VPC 
(virtual private cloud). The files in the `infrastructure` folder provide the Terraform resources necessary for provisioning the
networking and EC2 instance that the bastion host uses. The bastion host EC2 instance uses a default AWS AMI (machine image) that already
contains necessary configurations and packages (`awscli`, `boto3`, etc.).
