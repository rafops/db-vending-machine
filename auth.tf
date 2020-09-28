resource "aws_iam_role" "auth" {
  provider = aws.restore
  name     = "DBVending-${var.service_namespace}-Auth"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow"
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::${local.restore_account_id}:root"
      }
    }
  ]
}
EOF

  tags = {
    service = "DBVending-${var.service_namespace}"
  }
}

resource "aws_iam_policy" "auth" {
  provider    = aws.restore
  name        = "DBVending-${var.service_namespace}-Auth"
  description = "IAM policy for DB instance IAM authentication"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "rds-db:connect",
      "Resource": "arn:aws:rds-db:us-east-1:${local.restore_account_id}:dbuser:*/db_vending",
      "Condition": {
        "StringEquals": {
          "rds:db-tag/service": [
            "DBVending-${var.service_namespace}"
          ]
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "auth" {
  provider   = aws.restore
  role       = aws_iam_role.auth.id
  policy_arn = aws_iam_policy.auth.arn
}