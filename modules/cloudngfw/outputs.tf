output "cloudngfw_service_name" {
  description = "The service endpoint name exposed to tenant environment."
  value       = cloudngfwaws_ngfw.this.endpoint_service_name
}

output "fw_id" {
  description = "Id of the Cloud NGFW resource"
  value       = cloudngfwaws_ngfw.this.firewall_id
}
