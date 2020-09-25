variable "aws_region" {
  description = "The AWS region to create things in."
  type        = string
  default     = "us-east-1"
}

variable "backup_profile" {
  description = "The AWS profile for the AWS account where snapshots will be taken from. Usually a production account."
  type        = string
  default     = "db-vending-backup"
}

variable "backup_db_instance" {
  description = "The DB instance identifier where snapshots will be taken from. Usually a prodiction instance."
  type        = string
}

variable "restore_profile" {
  description = "The AWS profile for the AWS account where DB instances will be restored into."
  type        = string
  default     = "db-vending-restore"
}

variable "restore_vpc_id" {
  description = "The VPC ID where DB instances will be restored into."
  type        = string
}

variable "restore_subnet_ids" {
  description = "A list of subnet IDs where DB instances will be restored into. At least two subnets on the same VPC."
  type        = list(string)
}

variable "service_namespace" {
  description = "A unique namespace for a DB Vending Machine service. This allows setting up multiple vending machines per account. Must contain only camel cased words and numbers."
  type        = string
  default     = "Default"
}

variable "create_test_db" {
  description = "Creates a DB instance for testing/development purposes. To enable this option, set create_test_db = true in test.tfvars."
  type        = bool
  default     = false
}