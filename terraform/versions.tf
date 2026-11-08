# -----------------------------------------------------------------------------
# Terraform and provider requirements.
#
# The AWS provider reads credentials from the standard AWS environment variables
# or from your AWS profile. NEVER write access keys in any .tf or .tfvars file.
# -----------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40, < 7.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Every resource that supports tags receives these automatically.
  default_tags {
    tags = local.common_tags
  }
}
