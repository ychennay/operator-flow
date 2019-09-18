#!/usr/bin/env bash

# the following commands were used to quickly spin up and spin down EKS clusters

export NODEGROUP_STACK=eksctl-kubeflow-aws-nodegroup-cpu-nodegroup
export EKS_CLUSTER_STACK=eksctl-kubeflow-aws-cluster

# delete dependent nodegroup stack
aws cloudformation delete-stack --stack-name eksctl-kubeflow-aws-nodegroup-cpu-nodegroup --region=us-east-1
aws cloudformation wait stack-delete-complete --stack-name eksctl-kubeflow-aws-nodegroup-cpu-nodegroup --region=us-east-1
aws cloudformation delete-stack --stack-name eksctl-kubeflow-aws-cluster --region=us-east-1

pip3 install boto3 && pip3 install --upgrade requests
