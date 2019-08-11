
resource "aws_instance" "bastion" {
  instance_type               = "t2.medium"
  associate_public_ip_address = true
  ami                         = var.bastion_ami
  subnet_id                   = data.aws_subnet.operator_flow_public_subnet_id.id
  key_name                    = aws_key_pair.bastion_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.bastion_profile.name
  security_groups = [
  aws_security_group.bastion-security-group.id]

  tags = {
    Name = "operator_flow_bastion_host"
  }
}

resource "aws_eip" "bastion_host_ip" {
  instance = aws_instance.bastion.id
  vpc      = true
}

resource "aws_iam_role" "bastion_iam_role" {
  name               = "bastion_iam_role"
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

resource aws_iam_policy_attachment "eks_policy_attachment" {
  name       = aws_iam_role.bastion_iam_role.name
  policy_arn = data.aws_iam_policy.eks_full_policy.arn
}

resource aws_iam_policy_attachment "cloud_formation_policy_attachment" {
  name       = aws_iam_role.bastion_iam_role.name
  policy_arn = data.aws_iam_policy.cloudformation_full_policy.arn
}

resource aws_iam_policy_attachment "ec2_policy_attachment" {
  name       = aws_iam_role.bastion_iam_role.name
  policy_arn = data.aws_iam_policy.ec2_full_policy.arn
}

resource aws_iam_policy_attachment "iam_policy_attachment" {
  name       = aws_iam_role.bastion_iam_role.name
  policy_arn = data.aws_iam_policy.iam_full_policy.arn
}

resource aws_iam_policy_attachment "eks_cluster_management_policy" {
  name       = aws_iam_role.bastion_iam_role.name
  policy_arn = data.aws_iam_policy.eks_cluster_management_policy.arn
}


resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion_profile"
  role = aws_iam_role.bastion_iam_role.name
}


data "aws_iam_policy" "ec2_full_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

data "aws_iam_policy" "eks_cluster_management_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy" "cloudformation_full_policy" {
  arn = "arn:aws:iam::aws:policy/AWSCloudFormationFullAccess"
}

data "aws_iam_policy" "iam_full_policy" {
  arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

data "aws_iam_policy" "eks_full_policy" {
  arn = "arn:aws:iam::892003309670:policy/eks_allow_all_policy"
}


resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion_key"
  public_key = var.bastion_ssh_public_key
}

resource "aws_security_group" "bastion-security-group" {
  name   = "bastion-security-group"
  vpc_id = aws_vpc.operator_flow_vpc.id

  # restrict traffic to SSH
  ingress {
    from_port = 22
    protocol  = "TCP"
    to_port   = 22
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  egress {
    # allow all outbound traffic
    from_port = 0
    protocol  = -1
    to_port   = 0
    cidr_blocks = [
    "0.0.0.0/0"]
  }
}