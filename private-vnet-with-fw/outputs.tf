output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "bastion_ip" {
  value = azurerm_public_ip.vm_bastion_pip.ip_address
}

output "vnet_name" {
  value = azurerm_virtual_network.azfw_vnet.name
}

output "private_subnet" {
  value = azurerm_subnet.private_subnet.name
}

output "logic_app_subnet_delegation_id" {
  value = azurerm_subnet.logicapp_subnet_delegation.id
}

output "function_app_subnet_delegation_id" {
  value = azurerm_subnet.function_subnet_delegation.id
}

output "bastion_ssh_key" {
  value = "Bastion server using weka_dev_ssh_key (dev)"
}

output "bastion_user" {
  value = var.vm_username
}

output "sg_id" {
  value = azurerm_network_security_group.vm_server_nsg.id
}