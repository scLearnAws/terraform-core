output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of IDs for public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs for private subnets"
  value       = aws_subnet.private[*].id
}

output "nat_public_ip" {
  description = "Elastic IP attached to NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "web_security_group_id" {
  description = "ID of Public Web Security Group"
  value       = aws_security_group.web_sg.id
}

output "app_security_group_id" {
  description = "ID of Private App Security Group"
  value       = aws_security_group.app_sg.id
}