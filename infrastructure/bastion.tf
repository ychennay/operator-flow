resource "aws_instance" "bastion" {
  instance_type = "t2.micro"
  associate_public_ip_address = true
  ami = var.bastion_ami
  subnet_id = data.aws_subnet.operator_flow_public_subnet_id.id

  tags = {
    Name = "operator_flow_bastion_host"
  }
}
