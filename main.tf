terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
    backend "s3" {
        bucket         = "tf-state-core-c5da5b20ef07a4023ead994443" 
        key            = "terraform-core/terraform.tfstate"
        region         = "eu-central-1"
        use_lockfile = true
        encrypt      = true
    }
}

provider "aws" {
  region = "eu-central-1"
}

# 1. S3 Bucket for Remote State Storage
resource "aws_s3_bucket" "terraform_state" {
  bucket_prefix = "tf-state-core-"

  # Protect against accidental bucket deletion
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Environment = "Core-State"
    ManagedBy   = "Terraform"
  }
}

# Enable versioning so we can recover past states if corrupted
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Explicitly block all public access to the state bucket
resource "aws_s3_bucket_public_access_block" "terraform_state_public_block" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST" # Free Tier friendly
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Environment = "Core-State"
    ManagedBy   = "Terraform"
  }
}

# Outputs to copy into our backend configuration
output "s3_bucket_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "Name of the S3 bucket created for Terraform state"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "Name of the DynamoDB table created for Terraform state locking"
}