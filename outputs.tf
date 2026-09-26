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

output "web_security_group_id" {
  description = "ID of Public Web Security Group"
  value       = aws_security_group.web_sg.id
}

output "web_public_ip" {
  description = "Public IP of the Web Server"
  value       = aws_instance.web.public_ip
}

output "web_public_dns" {
  description = "Public DNS of the Web Server"
  value       = aws_instance.web.public_dns
}

output "terraform_core_role_arn" {
  description = "ARN of the IAM Role assumed by terraform-core's GitHub Actions workflow"
  value       = aws_iam_role.terraform_core.arn
}

output "terraform_app_role_arn" {
  description = "ARN of the IAM Role assumed by terraform-app's GitHub Actions workflow"
  value       = aws_iam_role.terraform_app.arn
}