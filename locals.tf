locals {
  source_account_id = data.aws_caller_identity.current.account_id
  destination_account_id = join("", regex(":(\\d+):role", aws_iam_role.vending.arn))
}