terraform {
  required_version = "~> 0.13.3"
}

provider "aws" {
  version = "~> 3.5.0"
  region  = var.aws_region
  profile = var.source_profile
}

provider "aws" {
  version = "~> 3.5.0"
  region  = var.aws_region
  profile = var.destination_profile
  alias   = "destination"
}

data "aws_caller_identity" "current" {}