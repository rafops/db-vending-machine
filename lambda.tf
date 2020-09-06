data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "create_snapshot" {
  description      = "Lamba function to create DB snapshots"
  filename         = "lambda.zip"
  function_name    = "create_snapshot"
  role             = aws_iam_role.lambda.arn
  handler          = "create_snapshot.handler"
  source_code_hash = filebase64sha256("lambda.zip")
  runtime          = "ruby2.7"
  timeout          = 60

  environment {
    variables = {
      LAMBDA_ROLE_ARN = "${aws_iam_role.lambda.arn}"
      SOURCE_DB_INSTANCE_IDENTIFIER = "${var.source_db_instance_identifier}"
    }
  }

  depends_on = [
    data.archive_file.lambda
  ]
}

resource "aws_iam_role" "lambda" {
  name = "lambda"
  path = "/db-vend/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    service = "db-vend"
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "db-vend-lambda"
  role   = aws_iam_role.lambda.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "rds:CreateDBSnapshot",
        "rds:ModifyDBSnapshotAttribute",
        "rds:DeleteDBSnapshot"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "lambda_log" {
  name              = "/aws/lambda/${aws_lambda_function.create_snapshot.function_name}"
  retention_in_days = var.log_retention
}

resource "aws_iam_policy" "lambda_log" {
  name        = "lambda-log"
  path        = "/db-vend/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_log" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_log.arn
}