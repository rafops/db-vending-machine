variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "us-east-1"
}

variable "backup_profile" {
  description = "The AWS profile for the AWS account where DB Vending Machine will take backups from. Usually a production account."
  default     = "db-vending-backup"
}

variable "restore_profile" {
  description = "The AWS profile for the account where DB Vending Machine will create DB instances."
  default     = "db-vending-restore"
}

variable "source_db_instance" {
  description = "The source DB instance identifier where snapshots will be taken from."
  default     = "db-vending-test"
}

variable "service_namespace" {
  description = "A unique namespace for a DB Vending Machine service. This allows setting up multiple DB Vending Machines per account. Must contain only camel cased words and numbers."
  default     = "Default"
}

variable "create_test_db" {
  description = "Creates a DB instance for testing/development purposes. To enable this option, set create_test_db = true in test.tfvars."
  default = false
}