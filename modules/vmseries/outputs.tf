output "instance" {
  description = "The full `aws_instance` object for the VM-Series instance."
  value       = aws_instance.this
}

output "instance_id" {
  description = "ID of the VM-Series EC2 instance."
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the VM-Series EC2 instance."
  value       = aws_instance.this.arn
}

output "interfaces" {
  description = "Map of VM-Series network interfaces. The entries are `aws_network_interface` objects."
  value       = aws_network_interface.this
}

output "private_ips" {
  description = "Map of primary private IPs, keyed by interface name."
  value       = { for k, v in aws_network_interface.this : k => v.private_ip }
}

output "public_ips" {
  description = "Map of public IPs created within the module."
  value       = { for k, v in aws_eip.this : k => v.public_ip }
}

output "mgmt_ip" {
  description = "Convenience: public IP of the management interface if one exists, else the private IP. `null` if no interface named `mgmt` was supplied."
  value = try(
    aws_eip.this["mgmt"].public_ip,
    aws_network_interface.this["mgmt"].private_ip,
    null
  )
}
