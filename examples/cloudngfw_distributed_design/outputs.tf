output "application_load_balancers" {
  description = <<-EOF
  FQDNs of Application Load Balancers
  EOF
  value       = { for k, v in module.app_alb : k => v.lb_fqdn }
}

output "cloudngfws" {
  description = "Cloud NGFW service name"
  value       = { for k, v in module.cloudngfw : k => v.cloudngfw_service_name }
}
