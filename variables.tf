variable "aws_region" {
  description = "AWS Region for deployment"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the main VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "availability_zones" {
  description = "AZs for subnets"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "ami_id" {
  description = "Pinned AMI ID for EC2 instances. Update deliberately, e.g. every few months for patches."
  type        = string
  default     = "ami-05f538da85d563285"
}

variable "github_org" {
  type    = string
  default = "scLearnAws"
}

variable "github_org_id" {
  type    = string
  default = "328701079"
}

variable "core_repo" {
  type    = string
  default = "terraform-core"
}

variable "core_repo_id" {
  type    = string
  default = "1368342384"
}

variable "app_repo" {
  type    = string
  default = "terraform-app"
}

variable "app_repo_id" {
  type    = string
  default = "1368341777"
}