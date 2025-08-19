##### Spokes VPC Load Balancers #####

output "application_load_balancers" {
  description = <<-EOF
  FQDNs of Application Load Balancers
  EOF
  value       = { for k, v in module.app_alb : k => v.lb_fqdn }
}

output "network_load_balancers" {
  description = <<-EOF
  FQDNs of Network Load Balancers.
  EOF
  value       = { for k, v in module.app_nlb : k => v.lb_fqdn }
}

output "cloudngfws" {
  value = module.cloudngfw["cloudngfws_security"].cloudngfw_service_name
}
