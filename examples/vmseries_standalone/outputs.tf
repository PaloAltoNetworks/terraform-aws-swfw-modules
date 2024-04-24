output "vmseries_public_ips" {
  description = "Map of public IPs created within `vmseries` module instances."
  value       = { for k, v in module.vmseries : k => v.public_ips }
}

output "vm_series_ipv6_addresses" {
  description = "Map of IPv6 addresses assigned to interfaces in `vmseries` module instances."
  value       = { for k, v in module.vmseries : k => { for ik, iv in v.interfaces : ik => [for ip in iv.ipv6_addresses : ip] } }
}