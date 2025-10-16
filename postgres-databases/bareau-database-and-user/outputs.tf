output "db_name" {
  description = "Name of the database"
  value       = postgresql_database.the_db.name
}

output "db_user" {
  description = "Name of the user/role"
  value       = postgresql_role.the_role.name
}

output "db_password" {
  description = "Password of the user"
  value       = random_password.the_password.result
  sensitive   = true
}
