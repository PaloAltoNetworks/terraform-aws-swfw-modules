output "instance_profile" {
  description = "The instance profile created for VM."
  value       = var.create_instance_profile ? aws_iam_instance_profile.this[0] : null
}

output "iam_role" {
  description = "The role used for policies."
  value       = var.create_role ? aws_iam_role.this[0] : null
}