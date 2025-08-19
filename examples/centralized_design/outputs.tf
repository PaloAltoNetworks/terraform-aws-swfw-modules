##### Security VPC #####

output "vmseries_public_ips" {
  description = "Map of public IPs created within `vmseries` module instances."
  value       = { for k, v in module.vmseries : k => v.public_ips }
}

##### App VPC #####

output "app_inspected_dns_name" {
  description = <<-EOF
  FQDN of App Internal Load Balancer.
  Can be used in VM-Series configuration to balance traffic between the application instances.
  EOF
  value       = [for l in module.app_nlb : l.lb_fqdn]
}

##### VM-Series ALB & NLB #####

output "public_alb_dns_name" {
  description = "FQDN of VM-Series External Application Load Balancer used in centralized design."
  value       = { for k, v in module.public_alb : k => v.lb_fqdn }
}

output "public_nlb_dns_name" {
  description = "FQDN of VM-Series External Network Load Balancer used in centralized design."
  value       = { for k, v in module.public_nlb : k => v.lb_fqdn }
}

##### Spokes ALB & NLB #####
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