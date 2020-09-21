resource "aws_sfn_state_machine" "sfn" {
  name     = "DBVending-${var.service_namespace}-StateMachine"
  role_arn = aws_iam_role.sfn.arn

  definition = <<EOF
{
  "Comment": "DB Vending Machine state machine",
  "StartAt": "CreateSnapshot",
  "States": {
    "CreateSnapshot": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.create_snapshot.arn}",
      "Next": "CheckSnapshotStatus"
    },
    "WaitWhileSnapshotIsCreating": {
      "Type": "Wait",
      "Seconds": 60,
      "Next": "CheckSnapshotStatus"
    },
    "CheckSnapshotStatus": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.check_snapshot_status.arn}",
      "Next": "IsSnapshotAvailable",
      "Retry": [ {
        "ErrorEquals": [ "States.ALL" ],
        "IntervalSeconds": 60,
        "MaxAttempts": 5
      } ]
    },
    "IsSnapshotAvailable": {
      "Type": "Choice",
      "Choices": [
        {
          "Not": {
            "Variable": "$.status",
            "StringEquals": "available"
          },
          "Next": "WaitWhileSnapshotIsCreating"
        }
      ],
      "Default": "Done"
    },
    "Done": {
      "Type": "Pass",
      "End": true  
    }
  }
}
EOF

  tags = {
    service = "DBVending-${var.service_namespace}"
  }
}

resource "aws_iam_role" "sfn" {
  name = "DBVending-${var.service_namespace}-StateMachine"

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
    service = "DBVending-${var.service_namespace}"
  }
}

resource "aws_iam_role_policy" "sfn" {
  name = "DBVending-${var.service_namespace}-StateMachine"
  role = aws_iam_role.sfn.id

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