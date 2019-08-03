locals {
  instance-userdata = <<EOF
#!/bin/bash
sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl awscli jq python3-pip
curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.7/2019-06-11/bin/linux/amd64/aws-iam-authenticator
openssl sha1 -sha256 aws-iam-authenticator
chmod +x ./aws-iam-authenticator
mkdir -p $HOME/bin && cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$HOME/bin:$PATH
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
export KUBEFLOW_SRC=/tmp/kubeflow-aws
export KUBEFLOW_TAG=v0.5-branch

curl https://github.com/ksonnet/ksonnet/releases/download/v0.11.0/ks_0.11.0_linux_amd64.tar.gz

mkdir -p ${KUBEFLOW_SRC} && cd ${KUBEFLOW_SRC}
curl https://raw.githubusercontent.com/kubeflow/kubeflow/${KUBEFLOW_TAG}/scripts/download.sh | bash
export KFAPP=kfapp
export REGION=us-east-1
export AWS_CLUSTER_NAME=kubeflow-aws

export KS_VER=0.12.0
export KS_PKG=ks_${KS_VER}_linux_amd64
wget -O /tmp/${KS_PKG}.tar.gz https://github.com/ksonnet/ksonnet/releases/download/v${KS_VER}/${KS_PKG}.tar.gz   --no-check-certificate
tar -xvf /tmp/$KS_PKG.tar.gz -C ${HOME}/bin
export PATH=$PATH:${HOME}/bin/$KS_PKG

${KUBEFLOW_SRC}/scripts/kfctl.sh init ${KFAPP} --platform aws \
--awsClusterName ${AWS_CLUSTER_NAME} \
--awsRegion ${REGION}

cd ${KFAPP}
${KUBEFLOW_SRC}/scripts/kfctl.sh generate platform


${KUBEFLOW_SRC}/scripts/kfctl.sh apply platform
EOF
}

resource "aws_instance" "bastion" {
  instance_type = "t2.micro"
  associate_public_ip_address = true
  ami = var.bastion_ami
  subnet_id = data.aws_subnet.operator_flow_public_subnet_id.id
  key_name = aws_key_pair.bastion_key.key_name
  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name
  user_data_base64 = base64encode(local.instance-userdata)

  security_groups = [
    aws_security_group.bastion-security-group.id]

  tags = {
    Name = "operator_flow_bastion_host"
  }
}

resource "aws_iam_role" "bastion_iam_role" {
  name = "bastion_iam_role"
  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "ec2.amazonaws.com"
    },
    "Effect": "Allow",
    "Sid": ""
  }
]
}
EOF

  tags = {
    product = "operator_flow"
  }
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion_profile"
  role = aws_iam_role.bastion_iam_role.name
}


resource "aws_key_pair" "bastion_key" {
  key_name = "bastion_key"
  public_key = var.bastion_ssh_public_key
}

resource "aws_security_group" "bastion-security-group" {
  name = "bastion-security-group"
  vpc_id = aws_vpc.operator_flow_vpc.id

  # restrict traffic to SSH
  ingress {
    from_port = 22
    protocol = "TCP"
    to_port = 22
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  egress {
    # allow all outbound traffic
    from_port = 0
    protocol = -1
    to_port = 0
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}