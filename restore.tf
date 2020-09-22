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

# TODO: Restrict resources
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
        "rds:CreateDBInstance",
        "rds:CopyDBSnapshot",
        "rds:DeleteDBInstance"
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