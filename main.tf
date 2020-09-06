terraform {
  required_version = "~> 0.13.2"
}

provider "aws" {
  version = "~> 3.5.0"
  region = var.aws_region
}

data "aws_db_instance" "source" {
  db_instance_identifier = var.source_db_instance_identifier
}