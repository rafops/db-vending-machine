variable "test_db_instance" {
  description = "Creates an RDS DB Instance for testing."
  default     = false
}

resource "aws_kms_key" "test" {
  count = var.test_db_instance ? 1 : 0

  description             = "DB Vending Machine test key"
  deletion_window_in_days = 7

  tags = {
    service = "db-vending-machine-test"
  }
}

resource "random_string" "password" {
  length  = 16
  special = false
}

# db.m4.large is the smallest instance that works with KMS key
resource "aws_db_instance" "test" {
  count = var.test_db_instance ? 1 : 0

  allocated_storage           = 20
  allow_major_version_upgrade = false
  apply_immediately           = true
  auto_minor_version_upgrade  = false
  backup_retention_period     = 0
  engine                      = "postgres"
  engine_version              = "12.3"
  identifier_prefix           = "db-vending-machine-test-"
  instance_class              = "db.m4.large"
  kms_key_id                  = element(aws_kms_key.test.*.arn, count.index)
  multi_az                    = false
  name                        = "test"
  password                    = random_string.password.result
  publicly_accessible         = true
  skip_final_snapshot         = true
  storage_encrypted           = true
  storage_type                = "gp2"
  username                    = "test"

  tags = {
    service = "db-vending-machine-test"
  }
}

output "address" {
  value = join("", aws_db_instance.test.*.address)
}

output "username" {
  value = join("", aws_db_instance.test.*.username)
}

output "password" {
  value = random_string.password.result
}

output "database_name" {
  value = join("", aws_db_instance.test.*.name)
}
