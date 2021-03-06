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
        "execution_id.$": "$$.Execution.Id"
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
        "MaxAttempts": 3
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
      "Next": "CheckSnapshotRekeyStatus",
      "Retry": [ {
        "ErrorEquals": [ "States.ALL" ],
        "IntervalSeconds": 60,
        "MaxAttempts": 3
      } ]
    },
    "CheckSnapshotRekeyStatus": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.check_snapshot_status.arn}",
      "Next": "IsSnapshotRekeyed",
      "Retry": [ {
        "ErrorEquals": [ "States.ALL" ],
        "IntervalSeconds": 60,
        "MaxAttempts": 3
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
      "Next": "CopySnapshot",
      "Retry": [ {
        "ErrorEquals": [ "States.ALL" ],
        "IntervalSeconds": 60,
        "MaxAttempts": 3
      } ]
    },


    "CopySnapshot": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.copy_snapshot.arn}",
      "Next": "CheckSnapshotCopyStatus",
      "Retry": [ {
        "ErrorEquals": [ "States.ALL" ],
        "IntervalSeconds": 60,
        "MaxAttempts": 3
      } ]
    },
    "CheckSnapshotCopyStatus": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.check_snapshot_copy_status.arn}",
      "Next": "IsSnapshotCopied",
      "Retry": [ {
        "ErrorEquals": [ "States.ALL" ],
        "IntervalSeconds": 60,
        "MaxAttempts": 3
      } ]
    },
    "IsSnapshotCopied": {
      "Type": "Choice",
      "Choices": [
        {
          "Not": {
            "Variable": "$.status",
            "StringEquals": "available"
          },
          "Next": "WaitWhileSnapshotIsCopying"
        }
      ],
      "Default": "RestoreInstance"
    },
    "WaitWhileSnapshotIsCopying": {
      "Type": "Wait",
      "Seconds": 60,
      "Next": "CheckSnapshotCopyStatus"
    },


    "RestoreInstance": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.restore_instance.arn}",
      "Parameters": {
        "db_instance_identifier": "${var.source_db_instance}",
        "db_snapshot_identifier.$": "$.db_snapshot_identifier"
      },
      "Next": "CheckInstanceStatus",
      "Retry": [ {
        "ErrorEquals": [ "States.ALL" ],
        "IntervalSeconds": 60,
        "MaxAttempts": 3
      } ]
    },
    "CheckInstanceStatus": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.check_instance_status.arn}",
      "Next": "IsInstanceRestored",
      "Retry": [ {
        "ErrorEquals": [ "States.ALL" ],
        "IntervalSeconds": 60,
        "MaxAttempts": 3
      } ]
    },
    "IsInstanceRestored": {
      "Type": "Choice",
      "Choices": [
        {
          "Not": {
            "Variable": "$.status",
            "StringEquals": "available"
          },
          "Next": "WaitWhileInstanceIsRestoring"
        }
      ],
      "Default": "Done"
    },
    "WaitWhileInstanceIsRestoring": {
      "Type": "Wait",
      "Seconds": 60,
      "Next": "CheckInstanceStatus"
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