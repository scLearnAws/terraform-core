terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# Practice local resource
resource "aws_s3_bucket" "practice_bucket" {
  bucket_prefix = "tf-local-practice-"

  tags = {
    Environment = "Stage2-Local"
    ManagedBy   = "Terraform"
  }
}

output "practice_bucket_name" {
  description = "The generated name of our local practice S3 bucket"
  value       = aws_s3_bucket.practice_bucket.id
}