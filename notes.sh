EXPORT NODEGROUP_STACK=eksctl-kubeflow-aws-nodegroup-cpu-nodegroup
EXPORT EKS_CLUSTER_STACK=eksctl-kubeflow-aws-cluster

# delete dependent nodegroup stack
aws cloudformation delete-stack --stack-name $NODEGROUP_STACK --region=us-east-1
aws cloudformation wait stack-delete-complete --stack-name $NODEGROUP_STACK
aws cloudformation delete-stack --stack-name eksctl-kubeflow-aws-cluster --region=us-east-1