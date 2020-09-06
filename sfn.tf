resource "aws_sfn_state_machine" "sfn" {
  name     = "db-vending-machine-sfn"
  role_arn = aws_iam_role.sfn.arn

  definition = <<EOF
{
  "Comment": "DB Vending Machine state machine",
  "StartAt": "CreateSnapshot",
  "States": {
    "CreateSnapshot": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.create_snapshot.arn}",
      "End": true
    }
  }
}
EOF

  tags = {
    service = "db-vending-machine"
  }
}

resource "aws_iam_role" "sfn" {
  name = "db-vending-machine-sfn"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "states.${var.aws_region}.amazonaws.com",
          "events.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    service = "db-vending-machine"
  }
}

resource "aws_iam_role_policy" "sfn" {
  name   = "db-vending-machine-sfn"
  role   = aws_iam_role.sfn.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "lambda:InvokeFunction",
        "states:StartExecution"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}