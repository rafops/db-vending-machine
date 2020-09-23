resource "aws_kms_key" "test" {
  count = var.create_test_db ? 1 : 0

  description             = "DB Vending Machine test key"
  deletion_window_in_days = 7

  tags = {
    service = "DBVending-${var.service_namespace}-Test"
  }
}

resource "random_string" "password" {
  length  = 16
  special = false
}

# db.m5.large is the smallest instance that works with KMS key
resource "aws_db_instance" "test" {
  count = var.create_test_db ? 1 : 0

  allocated_storage           = 20
  allow_major_version_upgrade = false
  apply_immediately           = true
  auto_minor_version_upgrade  = false
  backup_retention_period     = 0
  engine                      = "postgres"
  engine_version              = "12.3"
  identifier                  = var.backup_db_instance
  instance_class              = "db.m5.large"
  kms_key_id                  = element(aws_kms_key.test.*.arn, count.index)
  multi_az                    = false
  name                        = "test"
  password                    = element(random_string.password.*.result, count.index)
  publicly_accessible         = true
  skip_final_snapshot         = true
  storage_encrypted           = true
  storage_type                = "gp2"
  username                    = "test"

  tags = {
    service = "DBVending-${var.service_namespace}-Test"
  }
}