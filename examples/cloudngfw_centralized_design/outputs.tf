##### App VPC #####

#output "app_inspected_dns_name" {
#  description = <<-EOF
#  FQDN of App Internal Load Balancer.
#  Can be used in VM-Series configuration to balance traffic between the application instances.
#  EOF
#  value       = [for l in module.public_alb : l.lb_fqdn]
#}

##### Cloud NGFW #####
output "cloudngfws" {
  value = module.cloudngfw["cloudngfws_security_ew_ob"].cloudngfw_service_name
}
