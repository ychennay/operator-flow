#!/usr/bin/env bash

FILE=$HOME/.ssh/operator_flow_key.pub
EMAIL=ychennay@gmail.com

# check if an operator_flow public key exists in the SSH default directory, if not, create a new key pair.
if [ ! -f "$FILE" ]; then
  echo "operator_flow_key public key file not found."
  ssh-keygen -t rsa -b 4096 -C $EMAIL -f $HOME/.ssh/operator_flow_key
fi

echo "Public key already found."
TF_VAR_bastion_ssh_public_key=$(cat $HOME/.ssh/operator_flow_key.pub)
export TF_VAR_bastion_ssh_public_key
echo "bastion_ssh_public_key=\"$TF_VAR_bastion_ssh_public_key\"" > ../infrastructure/terraform.tfvars