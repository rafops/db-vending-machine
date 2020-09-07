data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "create_snapshot" {
  description      = "Create a DB snapshot"
  filename         = "lambda.zip"
  function_name    = "db_vending_machine_create_snapshot"
  role             = aws_iam_role.lambda.arn
  handler          = "create_snapshot.handler"
  source_code_hash = filebase64sha256("lambda.zip")
  runtime          = "ruby2.7"
  timeout          = 60

  depends_on = [
    data.archive_file.lambda
  ]
}

resource "aws_lambda_function" "describe_snapshot" {
  description      = "Check DB snapshot status"
  filename         = "lambda.zip"
  function_name    = "db_vending_machine_describe_snapshot"
  role             = aws_iam_role.lambda.arn
  handler          = "describe_snapshot.handler"
  source_code_hash = filebase64sha256("lambda.zip")
  runtime          = "ruby2.7"
  timeout          = 900

  depends_on = [
    data.archive_file.lambda
  ]
}

resource "aws_iam_role" "lambda" {
  name = "db-vending-machine-lambda"

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
    service = "db-vending-machine"
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "db-vending-machine-lambda"
  role   = aws_iam_role.lambda.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
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

resource "aws_cloudwatch_log_group" "lambda_log" {
  name              = "/aws/lambda/${aws_lambda_function.create_snapshot.function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "lambda_log" {
  name        = "db-vending-machine-lambda-log"
  description = "IAM policy for logging from a lambda"

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

resource "aws_iam_role_policy_attachment" "lambda_log" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_log.arn
}