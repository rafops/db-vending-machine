resource "aws_iam_role" "restore" {
  provider = aws.restore
  name     = "DBVending-${var.service_namespace}-Restore"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::${local.backup_account_id}:root"
      }
    }
  ]
}
EOF

  tags = {
    service = "DBVending-${var.service_namespace}"
  }
}

resource "aws_iam_policy" "restore" {
  provider    = aws.restore
  name        = "DBVending-${var.service_namespace}-Restore"
  description = "IAM policy for DB restore"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds:DescribeDBSnapshots",
        "rds:CopyDBSnapshot",
        "rds:DeleteDBSnapshot",
        "rds:DescribeDBInstances",
        "rds:RestoreDBInstanceFromDBSnapshot",
        "rds:DeleteDBInstance",
        "rds:AddTagsToResource"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:ListKeys",
        "kms:ListAliases",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "restore" {
  provider   = aws.restore
  role       = aws_iam_role.restore.id
  policy_arn = aws_iam_policy.restore.arn
}

resource "aws_kms_key" "restore" {
  description             = "DB Vending Machine ${var.service_namespace} restore key"
  deletion_window_in_days = 7

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow backup account to use this CMK",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.backup_account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow restore account to use this CMK",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.restore.arn}"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow restore account to manage grants",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.restore.arn}"
      },
      "Action": [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ],
      "Resource": "*",
      "Condition": {
        "Bool": {
          "kms:GrantIsForAWSResource": "true"
        }
      }
    }
  ]
}
EOF

  tags = {
    service = "DBVending-${var.service_namespace}"
  }
}

resource "aws_db_subnet_group" "restore" {
  provider   = aws.restore
  # only lowercase alphanumeric characters, hyphens, underscores, periods, and spaces allowed in "name"
  name       = lower("DBVending-${var.service_namespace}-Restore")
  subnet_ids = var.restore_subnet_ids

  tags = {
    service = "DBVending-${var.service_namespace}"
  }
}

resource "aws_security_group" "restore" {
  provider    = aws.restore
  name        = "DBVending-${var.service_namespace}-Restore"
  description = "Allow inbound traffic to restored DB instances"
  vpc_id      = var.restore_vpc_id

  ingress {
    description = "Allow connections to PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    service = "DBVending-${var.service_namespace}"
  }
}