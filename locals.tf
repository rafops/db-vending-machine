locals {
  backup_account_id = data.aws_caller_identity.current.account_id
  restore_account_id = join("", regex(":(\\d+):role", aws_iam_role.restore.arn))
}