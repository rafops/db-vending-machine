variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "us-east-1"
}

variable "source_db_instance_identifier" {
  description = "The identifier for source db instance used to take snapshots from."
}

variable "log_retention" {
  description = "The Lambda log retention period."
  default     = 14
}