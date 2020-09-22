resource "aws_sfn_state_machine" "state_machine" {
  name     = "DBVending-${var.service_namespace}-StateMachine"
  role_arn = aws_iam_role.state_machine.arn

  definition = <<EOF
{
  "Comment": "DB Vending Machine state machine",
  "StartAt": "CreateSnapshot",
  "States": {
    "CreateSnapshot": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.create_snapshot.arn}",
      "Parameters": {
        "db_instance_identifier": "${var.source_db_instance}",
        "service_namespace": "${var.service_namespace}"
      },
      "Next": "CheckSnapshotCreationStatus"
    },
    "CheckSnapshotCreationStatus": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.check_snapshot_status.arn}",
      "Next": "IsSnapshotCreated",
      "Retry": [ {
        "ErrorEquals": [ "States.ALL" ],
        "IntervalSeconds": 60,
        "MaxAttempts": 5
      } ]
    },
    "IsSnapshotCreated": {
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
      "Default": "RekeySnapshot"
    },
    "WaitWhileSnapshotIsCreating": {
      "Type": "Wait",
      "Seconds": 60,
      "Next": "CheckSnapshotCreationStatus"
    },
    "RekeySnapshot": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.rekey_snapshot.arn}",
      "Parameters": {
        "db_snapshot_identifier.$": "$.db_snapshot_identifier",
        "service_namespace": "${var.service_namespace}",
        "kms_key_id": "${aws_kms_key.restore.arn}"
      },
      "Next": "CheckSnapshotRekeyStatus",
      "Retry": [ {
        "ErrorEquals": [ "States.ALL" ],
        "IntervalSeconds": 60,
        "MaxAttempts": 5
      } ]
    },
    "CheckSnapshotRekeyStatus": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.check_snapshot_status.arn}",
      "Next": "IsSnapshotRekeyed",
      "Retry": [ {
        "ErrorEquals": [ "States.ALL" ],
        "IntervalSeconds": 60,
        "MaxAttempts": 5
      } ]
    },
    "IsSnapshotRekeyed": {
      "Type": "Choice",
      "Choices": [
        {
          "Not": {
            "Variable": "$.status",
            "StringEquals": "available"
          },
          "Next": "WaitWhileSnapshotIsRekeying"
        }
      ],
      "Default": "ShareSnapshot"
    },
    "WaitWhileSnapshotIsRekeying": {
      "Type": "Wait",
      "Seconds": 60,
      "Next": "CheckSnapshotRekeyStatus"
    },
    "ShareSnapshot": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.share_snapshot.arn}",
      "Parameters": {
        "db_snapshot_identifier.$": "$.db_snapshot_identifier",
        "restore_account_id": "${local.restore_account_id}"
      },
      "Next": "Done",
      "Retry": [ {
        "ErrorEquals": [ "States.ALL" ],
        "IntervalSeconds": 60,
        "MaxAttempts": 5
      } ]
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

resource "aws_iam_role" "state_machine" {
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

resource "aws_iam_role_policy" "state_machine" {
  name = "DBVending-${var.service_namespace}-StateMachine"
  role = aws_iam_role.state_machine.id

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