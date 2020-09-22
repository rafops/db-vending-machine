# TODO: Restrict resources
resource "aws_iam_policy" "backup" {
  name     = "DBVending-${var.service_namespace}-Backup"
  description = "IAM policy for DB backups"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds:DescribeDBInstances",
        "rds:CreateDBSnapshot",
        "rds:CopyDBSnapshot",
        "rds:AddTagsToResource",
        "rds:DescribeDBSnapshots",
        "rds:ModifyDBSnapshotAttribute",
        "rds:DeleteDBSnapshot"
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

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.lambda.id
  policy_arn = aws_iam_policy.backup.arn
}