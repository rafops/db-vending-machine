output "aws_region" {
  value = var.aws_region
}

output "source_profile" {
  value = var.source_profile
}

output "destination_profile" {
  value = var.destination_profile
}

output "destination_account_id" {
  value = local.destination_account_id
}

output "service_namespace" {
  value = var.service_namespace
}

output "state_machine_arn" {
  value = aws_sfn_state_machine.state_machine.arn
}