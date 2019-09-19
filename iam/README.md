## Identity Access Management (IAM) Roles

This repo contains the IAM policies required to run various pieces of KubeFlow infrastructure. These policies should be attached to the `NodeInstanceRole` that is assumed by the worker node instances
used by the KubeFlow Kubernetes cluster.

1. `eks_trust_policy.json`: this allows the EKS service to assume the given role.
2. `eks_node_instance_role_trust_policy.json`: this allows each individual EKS worker node (an EC2 instance) to assume the node instance roles.
3. `NodeInstanceRole/iam_csi_fsx_policy.json`: this policy allows the worker nodes to access `lustre.fsx`, an optimized file volume persistence layer
optimized for machine learning use cases.
4. `EKS_CNI_policy.json`: this policy gives the individual node instances the permission to modify IP address configurations. It is used by the CNI (container network interface) to modify Elastic Network Interfaces.