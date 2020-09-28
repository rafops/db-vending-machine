data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

## Create snapshot

resource "aws_lambda_function" "create_snapshot" {
  description      = "Create a snapshot from a DB instance"
  filename         = "lambda.zip"
  function_name    = "DBVending_${var.service_namespace}_CreateSnapshot"
  role             = aws_iam_role.lambda.arn
  handler          = "create_snapshot.handler"
  source_code_hash = filebase64sha256("lambda.zip")
  runtime          = "ruby2.7"
  timeout          = 60

  environment {
    variables = {
      service_namespace = "${var.service_namespace}"
    }
  }

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
  description      = "Check status of a snapshot"
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
  description      = "Re-key a snapshot with vending managed CMK"
  filename         = "lambda.zip"
  function_name    = "DBVending_${var.service_namespace}_RekeySnapshot"
  role             = aws_iam_role.lambda.arn
  handler          = "rekey_snapshot.handler"
  source_code_hash = filebase64sha256("lambda.zip")
  runtime          = "ruby2.7"
  timeout          = 60

  environment {
    variables = {
      kms_key_id = "${aws_kms_key.vending.arn}"
    }
  }

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
  description      = "Share a snapshot with the restore account"
  filename         = "lambda.zip"
  function_name    = "DBVending_${var.service_namespace}_ShareSnapshot"
  role             = aws_iam_role.lambda.arn
  handler          = "share_snapshot.handler"
  source_code_hash = filebase64sha256("lambda.zip")
  runtime          = "ruby2.7"
  timeout          = 60

  environment {
    variables = {
      destination_account_id = "${local.destination_account_id}"
    }
  }

  depends_on = [
    data.archive_file.lambda,
    aws_iam_role_policy_attachment.logs
  ]
}

resource "aws_cloudwatch_log_group" "share_snapshot_logs" {
  name              = "/aws/lambda/${aws_lambda_function.share_snapshot.function_name}"
  retention_in_days = 14
}

## Copy snapshot

resource "aws_lambda_function" "copy_snapshot" {
  description      = "Copy a snapshot from the source to the destination account"
  filename         = "lambda.zip"
  function_name    = "DBVending_${var.service_namespace}_CopySnapshot"
  role             = aws_iam_role.lambda.arn
  handler          = "copy_snapshot.handler"
  source_code_hash = filebase64sha256("lambda.zip")
  runtime          = "ruby2.7"
  timeout          = 60

  environment {
    variables = {
      service_namespace = "${var.service_namespace}",
      kms_key_id = "${aws_kms_key.vending.arn}",
      source_account_id = "${local.source_account_id}",
      vending_role_arn = "${aws_iam_role.vending.arn}"
    }
  }

  depends_on = [
    data.archive_file.lambda,
    aws_iam_role_policy_attachment.logs
  ]
}

resource "aws_cloudwatch_log_group" "copy_snapshot_logs" {
  name              = "/aws/lambda/${aws_lambda_function.copy_snapshot.function_name}"
  retention_in_days = 14
}

## Check snapshot copy

resource "aws_lambda_function" "check_snapshot_copy_status" {
  description      = "Check the copy status of a snapshot"
  filename         = "lambda.zip"
  function_name    = "DBVending_${var.service_namespace}_CheckSnapshotCopyStatus"
  role             = aws_iam_role.lambda.arn
  handler          = "check_snapshot_copy_status.handler"
  source_code_hash = filebase64sha256("lambda.zip")
  runtime          = "ruby2.7"
  timeout          = 60

  environment {
    variables = {
      vending_role_arn = "${aws_iam_role.vending.arn}"
    }
  }

  depends_on = [
    data.archive_file.lambda,
    aws_iam_role_policy_attachment.logs
  ]
}

resource "aws_cloudwatch_log_group" "check_snapshot_copy_status_logs" {
  name              = "/aws/lambda/${aws_lambda_function.check_snapshot_copy_status.function_name}"
  retention_in_days = 14
}

## Restore instance

resource "aws_lambda_function" "restore_instance" {
  description      = "Restore a DB instance from a snapshot"
  filename         = "lambda.zip"
  function_name    = "DBVending_${var.service_namespace}_RestoreInstance"
  role             = aws_iam_role.lambda.arn
  handler          = "restore_instance.handler"
  source_code_hash = filebase64sha256("lambda.zip")
  runtime          = "ruby2.7"
  timeout          = 60

  environment {
    variables = {
      service_namespace = "${var.service_namespace}",
      security_group_id = "${aws_security_group.vending.id}",
      vending_role_arn = "${aws_iam_role.vending.arn}"
    }
  }

  depends_on = [
    data.archive_file.lambda,
    aws_iam_role_policy_attachment.logs
  ]
}

resource "aws_cloudwatch_log_group" "restore_instance_logs" {
  name              = "/aws/lambda/${aws_lambda_function.restore_instance.function_name}"
  retention_in_days = 14
}

## Check instance status

resource "aws_lambda_function" "check_instance_status" {
  description      = "Check restored DB instance status"
  filename         = "lambda.zip"
  function_name    = "DBVending_${var.service_namespace}_CheckInstanceStatus"
  role             = aws_iam_role.lambda.arn
  handler          = "check_instance_status.handler"
  source_code_hash = filebase64sha256("lambda.zip")
  runtime          = "ruby2.7"
  timeout          = 60

  environment {
    variables = {
      vending_role_arn = "${aws_iam_role.vending.arn}"
    }
  }

  depends_on = [
    data.archive_file.lambda,
    aws_iam_role_policy_attachment.logs
  ]
}

resource "aws_cloudwatch_log_group" "check_instance_status_logs" {
  name              = "/aws/lambda/${aws_lambda_function.check_instance_status.function_name}"
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

resource "aws_iam_policy" "lambda" {
  name     = "DBVending-${var.service_namespace}-Lambda"
  description = "IAM policy for Lambdas"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds:CreateDBSnapshot",
        "rds:CopyDBSnapshot",
        "rds:AddTagsToResource",
        "rds:DescribeDBSnapshots",
        "rds:ModifyDBSnapshotAttribute",
        "rds:DeleteDBSnapshot",
        "rds:DescribeDBInstances"
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
    },
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "${aws_iam_role.vending.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.id
  policy_arn = aws_iam_policy.lambda.arn
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