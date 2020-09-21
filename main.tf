terraform {
  required_version = "~> 0.13.2"
}

provider "aws" {
  version = "~> 3.5.0"
  region  = var.aws_region
  profile = var.backup_profile
}

provider "aws" {
  version = "~> 3.5.0"
  region  = var.aws_region
  profile = var.restore_profile
  alias   = "restore"
}

data "aws_caller_identity" "current" {}

data "aws_db_instance" "source_db_instance" {
  db_instance_identifier = var.source_db_instance
}