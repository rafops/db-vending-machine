data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

## Create snapshot

resource "aws_lambda_function" "create_snapshot" {
  description      = "Create a DB snapshot from DB instance"
  filename         = "lambda.zip"
  function_name    = "DBVending_${var.service_namespace}_CreateSnapshot"
  role             = aws_iam_role.lambda.arn
  handler          = "create_snapshot.handler"
  source_code_hash = filebase64sha256("lambda.zip")
  runtime          = "ruby2.7"
  timeout          = 60

  # environment {
  #   variables = {
  #         "db_instance_identifier": "${var.source_db_instance}",
  #         "service_namespace": "${var.service_namespace}"

  #     SOURCE_DB_INSTANCE = "${var.source_db_instance}"
  #     SERVICE_NAMESPACE  = "${var.service_namespace}"
  #   }
  # }

  depends_on = [
    data.archive_file.lambda,
    aws_iam_role_policy_attachment.logs
  ]
}

resource "aws_cloudwatch_log_group" "create_snapshot_logs" {
  name              = "/aws/lambda/${aws_lambda_function.create_snapshot.function_name}"
  retention_in_days = 14
}

## Check snapshot

resource "aws_lambda_function" "check_snapshot_status" {
  description      = "Wait while DB snapshot is being created"
  filename         = "lambda.zip"
  function_name    = "DBVending_${var.service_namespace}_CheckSnapshotStatus"
  role             = aws_iam_role.lambda.arn
  handler          = "check_snapshot_status.handler"
  source_code_hash = filebase64sha256("lambda.zip")
  runtime          = "ruby2.7"
  timeout          = 60

  depends_on = [
    data.archive_file.lambda,
    aws_iam_role_policy_attachment.logs
  ]
}

resource "aws_cloudwatch_log_group" "check_snapshot_status_logs" {
  name              = "/aws/lambda/${aws_lambda_function.check_snapshot_status.function_name}"
  retention_in_days = 14
}

## Re-key snapshot

resource "aws_lambda_function" "rekey_snapshot" {
  description      = "Re-key DB snapshot with vending accessible CMK"
  filename         = "lambda.zip"
  function_name    = "DBVending_${var.service_namespace}_RekeySnapshot"
  role             = aws_iam_role.lambda.arn
  handler          = "rekey_snapshot.handler"
  source_code_hash = filebase64sha256("lambda.zip")
  runtime          = "ruby2.7"
  timeout          = 60

  # environment {
  #   variables = {
  #     SERVICE_NAMESPACE = "${var.service_namespace}"
  #     RESTORE_KMS_ARN = "${aws_kms_key.restore.arn}"
  #   }
  # }

  depends_on = [
    data.archive_file.lambda,
    aws_iam_role_policy_attachment.logs
  ]
}

resource "aws_cloudwatch_log_group" "rekey_snapshot_logs" {
  name              = "/aws/lambda/${aws_lambda_function.rekey_snapshot.function_name}"
  retention_in_days = 14
}

## Share snapshot

resource "aws_lambda_function" "share_snapshot" {
  description      = "Share DB snapshot with vending account"
  filename         = "lambda.zip"
  function_name    = "DBVending_${var.service_namespace}_ShareSnapshot"
  role             = aws_iam_role.lambda.arn
  handler          = "share_snapshot.handler"
  source_code_hash = filebase64sha256("lambda.zip")
  runtime          = "ruby2.7"
  timeout          = 60

  depends_on = [
    data.archive_file.lambda,
    aws_iam_role_policy_attachment.logs
  ]
}

resource "aws_cloudwatch_log_group" "share_snapshot_logs" {
  name              = "/aws/lambda/${aws_lambda_function.share_snapshot.function_name}"
  retention_in_days = 14
}

## Lambda execution role and policy

resource "aws_iam_role" "lambda" {
  name     = "DBVending-${var.service_namespace}-Lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
}
EOF

  tags = {
    service = "DBVending-${var.service_namespace}"
  }
}

resource "aws_iam_policy" "logs" {
  name        = "DBVending-${var.service_namespace}-Logs"
  description = "IAM policy for logging Lambda execution"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.logs.arn
}


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
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
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
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
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
      "Sid": "Allow restore account to grants",
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