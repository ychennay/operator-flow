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
echo 'export PATH=$HOME/bin:$PATH' >>~/.bashrc

export KUBEFLOW_SRC=/tmp/kubeflow-aws
export KUBEFLOW_TAG=v0.5-branch

mkdir -p ${KUBEFLOW_SRC} && cd ${KUBEFLOW_SRC}
curl https://raw.githubusercontent.com/kubeflow/kubeflow/${KUBEFLOW_TAG}/scripts/download.sh | bash
export KFAPP=kfapp
export REGION=us-east-1
export AWS_CLUSTER_NAME=kubeflow-aws

export KS_VER=0.13.1
export KS_PKG=ks_${KS_VER}_linux_amd64
wget -O /tmp/${KS_PKG}.tar.gz https://github.com/ksonnet/ksonnet/releases/download/v${KS_VER}/${KS_PKG}.tar.gz --no-check-certificate
tar -xvf /tmp/$KS_PKG.tar.gz -C ${HOME}/bin
export PATH=$PATH:${HOME}/bin/$KS_PKG
echo 'export PATH=$PATH:${HOME}/bin/$KS_PKG' >~/.bash_rc

# initialize and generate templates for platform config
${KUBEFLOW_SRC}/scripts/kfctl.sh init ${KFAPP} --platform aws \
  --awsClusterName ${AWS_CLUSTER_NAME} \
  --awsRegion ${REGION}

# apply configurations
cd ${KFAPP}
${KUBEFLOW_SRC}/scripts/kfctl.sh generate platform

${KUBEFLOW_SRC}/scripts/kfctl.sh apply platform

${KUBEFLOW_SRC}/scripts/kfctl.sh generate k8s

${KUBEFLOW_SRC}/scripts/kfctl.sh apply k8s

# install python aws api
pip3 install boto3 && pip3 install --upgrade r555satequests
