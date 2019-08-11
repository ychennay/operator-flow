output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_elastic_ip" {
  value = aws_eip.bastion_host_ip.id
}