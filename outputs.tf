output "address" {
  value = join("", aws_db_instance.test.*.address)
}

output "username" {
  value = join("", aws_db_instance.test.*.username)
}

output "password" {
  value = random_string.password.result
}

output "database_name" {
  value = join("", aws_db_instance.test.*.name)
}