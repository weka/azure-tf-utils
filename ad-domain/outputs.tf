output "ad_private_ip" {
  value = azurerm_windows_virtual_machine.vm_domain_controller.private_ip_address
}

output "ad_public_ip" {
  value = azurerm_windows_virtual_machine.vm_domain_controller.public_ip_address
}

output "rg_name" {
  value = azurerm_resource_group.rg.name
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "smb_domain_name" {
  value = var.active_directory_domain
}

output "smb_domain_netbios_name" {
  value = var.active_directory_netbios_name
}
