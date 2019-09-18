## The Bootstrap Module

The `generate_keys.sh` shell script is used to generate a new SSH key required to SSH into the bastion host EC2 instance.

The key is saved and then an environment variable called `TF_VAR_bastion_ssh_public_key` is exported, allowing Terraform to provision
the EC2 instance with secure user-specific credentials.

The `notes.sh` and `user_data.sh` shell scripts contain commands that need to be executed once SSHed into the bastion host to begin setting up
Kubernetes and KubeFlow.

The `notes.sh` contains helper commands for creating and rolling back CloudFormation stacks that actually provision the EKS cluster infrastructure.
