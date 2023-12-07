provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_public_ip" "pip_azfw" {
  name                = "${var.prefix}-fw-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
}

resource "azurerm_virtual_network" "azfw_vnet" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.address_space]
}

resource "azurerm_subnet" "azfw_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.azfw_vnet.name
  address_prefixes     = [var.address_prefixes_fw]
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "${var.prefix}-private-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.azfw_vnet.name
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.Web"]
  address_prefixes     = [var.private_address_prefixes]
}

resource "azurerm_subnet" "public_subnet" {
  name                 = "${var.prefix}-public-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.azfw_vnet.name
  address_prefixes     = [var.public_address_prefixes]
}

resource "azurerm_subnet" "function_subnet_delegation" {
  name                 = "${var.prefix}-subnet-delegation"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.azfw_vnet.name
  address_prefixes     = [var.function_app_subnet_delegation_cidr]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.Web"]
  delegation {
    name = "subnet-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "logicapp_subnet_delegation" {
  name                 = "${var.prefix}-logicapp-delegation"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.azfw_vnet.name
  address_prefixes     = [var.logic_app_subnet_delegation_cidr]
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Web"]
  delegation {
    name = "logic-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_public_ip" "vm_bastion_pip" {
  name                = "${var.prefix}-bastion-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "vm_bastion_nic" {
  name                = "${var.prefix}-bastion-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_bastion_pip.id
  }
}

resource "azurerm_network_security_group" "vm_server_nsg" {
  name                = "${var.prefix}-private-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "vm_bastion_nsg" {
  name                = "${var.prefix}-bastion-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "allow-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "vm_bastion_nsg_association" {
  network_interface_id      = azurerm_network_interface.vm_bastion_nic.id
  network_security_group_id = azurerm_network_security_group.vm_bastion_nsg.id
}

resource "azurerm_linux_virtual_machine" "vm_bastion" {
  name                            = "${var.prefix}-bastion-vm"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  computer_name                   = "${var.prefix}-bastion"
  size                            = var.instance_type
  admin_username                  = var.vm_username
  network_interface_ids           = [azurerm_network_interface.vm_bastion_nic.id]
  disable_password_authentication = true
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = "50"
  }
  admin_ssh_key {
    public_key = var.ssh_public_key
    username   = var.vm_username
  }
  source_image_id = var.source_image_id
}

resource "azurerm_firewall_policy" "azfw_policy" {
  name                     = "${var.prefix}-fw-policy"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku                      = "Premium"
  threat_intelligence_mode = "Alert"
}

resource "azurerm_firewall_policy_rule_collection_group" "prcg" {
  name               = "${var.prefix}-firewall-policy-rule-group"
  firewall_policy_id = azurerm_firewall_policy.azfw_policy.id
  priority           = 300
  application_rule_collection {
    name     = "appRc1"
    priority = 101
    action   = "Allow"
    rule {
      name = "appRule1"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = ["www.microsoft.com", "*.blob.core.windows.net", "*.azurewebsites.net"]
      source_addresses  = [var.private_address_prefixes]
    }
  }
  network_rule_collection {
    name     = "netRc1"
    priority = 200
    action   = "Allow"
    rule {
      name                  = "netRule1"
      protocols             = ["TCP"]
      source_addresses      = [var.private_address_prefixes]
      destination_addresses = ["*"]
      destination_ports     = ["8000", "8999"]
    }
  }
}

resource "azurerm_firewall" "fw" {
  name                = "${var.prefix}-fw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Premium"
  zones               = ["1"]
  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.azfw_subnet.id
    public_ip_address_id = azurerm_public_ip.pip_azfw.id
  }
  firewall_policy_id = azurerm_firewall_policy.azfw_policy.id
}

resource "azurerm_route_table" "rt" {
  name                          = "${var.prefix}-rt-fw"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = false
  route {
    name                   = "azfwDefaultRoute"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.fw.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "private_subnet_rt_association" {
  subnet_id      = azurerm_subnet.private_subnet.id
  route_table_id = azurerm_route_table.rt.id
}