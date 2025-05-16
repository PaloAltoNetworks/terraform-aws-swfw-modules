output "application_load_balancers" {
  description = <<-EOF
  FQDNs of Application Load Balancers
  EOF
  value       = { for k, v in module.public_alb : k => v.lb_fqdn }
}

output "network_load_balancers" {
  description = <<-EOF
  FQDNs of Network Load Balancers.
  EOF
  value       = { for k, v in module.public_nlb : k => v.lb_fqdn }
}

output "cloudngfws" {
  #value = module.cloudngfw["cloudngfws_security_app1"].cloudngfw_service_name
  value = { for k, v in module.cloudngfw : k => v.cloudngfw_service_name }
}
