output "bastion_public_ip" {
  description = "public ip address of bastion"
  value       = azurerm_public_ip.bastion.*.ip_address
}

output "bastion_private_ip" {
  description = "private ip address of bastion"
  value       = azurerm_network_interface.bastion.*.private_ip_address
}

output "manager_ips" {
  description = "list of ip addresses of manager nodes"
  value       = join(",", azurerm_network_interface.manager.*.private_ip_address)
}

output "suffix" {
  description = "random suffix generated"
  value       = random_pet.suffix.id
}

output "full_name" {
  description = "random suffix generated"
  value       = local.full_name
}

output "worker_ips" {
  description = "list of ip addresses of worker nodes"
  value       = join(",", azurerm_network_interface.worker.*.private_ip_address)
}

output "lb_public_ip" {
  description = "ip address of the lb for the workers"
  value       = length(local.lb_ports_public) > 0 ? azurerm_public_ip.public_ip[0].ip_address : ""
}
