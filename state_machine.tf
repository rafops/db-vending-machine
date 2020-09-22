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
        "service_namespace": "${var.service_namespace}",
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
      "Parameters": {
        "db_snapshot_identifier.$": "$.db_snapshot_identifier",
        "kms_key_id": "${aws_kms_key.restore.arn}"
      },
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
      "Parameters": {
        "db_snapshot_identifier.$": "$.db_snapshot_identifier",
        "restore_account_id": "${local.restore_account_id}"
      },
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
      "Parameters": {
        "db_snapshot_account_id": "${local.backup_account_id}",
        "db_snapshot_region": "${var.aws_region}",
        "db_snapshot_identifier.$": "$.db_snapshot_identifier",
        "restore_role_arn": "${aws_iam_role.restore.arn}",
        "kms_key_id": "${aws_kms_key.restore.arn}",
        "service_namespace": "${var.service_namespace}"
      },
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
      "Parameters": {
        "db_snapshot_identifier.$": "$.db_snapshot_identifier",
        "restore_role_arn": "${aws_iam_role.restore.arn}"
      },
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
      "Default": "Done"
    },
    "WaitWhileSnapshotIsCopying": {
      "Type": "Wait",
      "Seconds": 60,
      "Next": "CheckSnapshotCopyStatus"
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