output "aws_region" {
  value = var.aws_region
}

output "backup_profile" {
  value = var.backup_profile
}

output "restore_profile" {
  value = var.restore_profile
}

output "state_machine_arn" {
  value = aws_sfn_state_machine.state_machine.arn
}