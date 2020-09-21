data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "create_snapshot" {
  description      = "Create a DB snapshot from DB instance"
  filename         = "lambda.zip"
  function_name    = "DBVending_${var.service_namespace}_CreateSnapshot"
  role             = aws_iam_role.lambda.arn
  handler          = "create_snapshot.handler"
  source_code_hash = filebase64sha256("lambda.zip")
  runtime          = "ruby2.7"
  timeout          = 60

  depends_on = [
    data.archive_file.lambda,
    aws_iam_role_policy_attachment.lambda_logs
  ]
}

resource "aws_cloudwatch_log_group" "create_snapshot_logs" {
  name              = "/aws/lambda/${aws_lambda_function.create_snapshot.function_name}"
  retention_in_days = 14
}

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
    aws_iam_role_policy_attachment.lambda_logs
  ]
}

resource "aws_cloudwatch_log_group" "check_snapshot_status_logs" {
  name              = "/aws/lambda/${aws_lambda_function.check_snapshot_status.function_name}"
  retention_in_days = 14
}

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
    aws_iam_role_policy_attachment.lambda_logs
  ]
}

resource "aws_cloudwatch_log_group" "share_snapshot_logs" {
  name              = "/aws/lambda/${aws_lambda_function.share_snapshot.function_name}"
  retention_in_days = 14
}

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

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.logs.arn
}

# TODO: Restrict resources based on var.source_db_instance
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
        "rds:AddTagsToResource",
        "rds:DescribeDBSnapshots",
        "rds:ModifyDBSnapshotAttribute",
        "rds:DeleteDBSnapshot"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_backup" {
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

# TODO: Restrict resources based on service tags
resource "aws_iam_role_policy" "restore" {
  provider = aws.restore
  name     = "DBVending-${var.service_namespace}-Restore"
  role     = aws_iam_role.restore.id

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

resource "aws_kms_grant" "grant" {
  name              = "DBVending-${var.service_namespace}"
  key_id            = data.aws_db_instance.source_db_instance.kms_key_id
  grantee_principal = aws_iam_role.restore.arn
  operations        = [
    "Encrypt",
    "Decrypt",
    "GenerateDataKey",
    "ReEncryptFrom",
    "ReEncryptTo",
    "DescribeKey"
  ]
}