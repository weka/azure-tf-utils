##########################################################
# Create base infrastructure for DC
##########################################################
locals {
  import_ad_module       = "Import-Module ActiveDirectory"
  usr_attributes_command = "Set-ADUser -Identity ${var.vm_username} -Add @{ gidNumber = 12345 ; uid = 12345; uidNumber = 12345 }"
  powershell_command     = "${local.import_ad_module}; ${local.usr_attributes_command};"
  ad_script = templatefile("${path.module}/setup.ps1", {
    password                      = var.domadminpassword
    active_directory_domain       = var.active_directory_domain
    active_directory_netbios_name = var.active_directory_netbios_name
  })

  resource_group_name = var.resource_group_name != null ? var.resource_group_name : "${var.prefix}-rg"
}

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = local.resource_group_name
  location = var.location
  tags     = merge({ "ad_domain" : "${var.prefix}-ad" })
}

data "azurerm_resource_group" "rg" {
  name = local.resource_group_name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  address_space       = [var.address_space]
  dns_servers         = [cidrhost(var.address_prefix, 10)]
  tags                = merge({ "ad_domain" : "${var.prefix}-ad" })
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.address_prefix]

}

# public ip - dc
resource "azurerm_public_ip" "dc_public_ip" {
  count               = var.enable_public_ip_address ? 1 : 0
  name                = "${var.prefix}-public-ip"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = var.ip_address_allocation_method // "Dynamic"
  tags                = merge({ "ad_domain" : "${var.prefix}-ad" })
}

# network interface - dc
resource "azurerm_network_interface" "dc_nic" {
  name                = "${var.prefix}-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = merge({ "ad_domain" : "${var.prefix}-ad" })

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.address_prefix, 10)
    public_ip_address_id          = var.enable_public_ip_address ? azurerm_public_ip.dc_public_ip[0].id : null
  }
}

resource "azurerm_network_security_group" "dc_nsg" {
  name                = "${var.prefix}-nsg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  # Security rule can also be defined with resource azurerm_network_security_rule, here just defining it inline.
  security_rule {
    name                       = "rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "winrmhttp"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "dns"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "ssh"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = merge({ "ad_domain" : var.active_directory_domain })
}

# Subnet and NSG association DC
resource "azurerm_subnet_network_security_group_association" "dc_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.dc_nsg.id
}

#VM object for the DC - contrary to the member server, this one is static so there will be only a single DC
resource "azurerm_windows_virtual_machine" "vm_domain_controller" {
  name                  = "${var.prefix}-vm"
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.dc_nic.id]
  size                  = var.vm_size
  admin_username        = var.vm_username
  admin_password        = var.vm_password
  computer_name         = "${var.prefix}-vm"

  winrm_listener {
    protocol = "Http"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  dynamic "source_image_reference" {
    for_each = var.source_image_id != null ? [] : [1]
    content {
      publisher = var.windows_distribution_list[lower(var.windows_distribution_name)]["publisher"]
      offer     = var.windows_distribution_list[lower(var.windows_distribution_name)]["offer"]
      sku       = var.windows_distribution_list[lower(var.windows_distribution_name)]["sku"]
      version   = var.windows_distribution_list[lower(var.windows_distribution_name)]["version"]
    }
  }
  tags       = merge({ "ad_domain" : var.active_directory_domain })
  depends_on = [azurerm_public_ip.dc_public_ip, azurerm_network_interface.dc_nic]
}

# Promote VM to be a Domain Controller
# based on https://github.com/ghostinthewires/terraform-azurerm-promote-dc

resource "azurerm_virtual_machine_extension" "create_active_directory_forest" {
  name                 = "${var.prefix}-create-active-directory-forest"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm_domain_controller.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings   = <<SETTINGS
    {
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted -Command $is=[IO.MemoryStream]::New([System.Convert]::FromBase64String(\\\"${base64gzip(local.ad_script)}\\\")); $gs=[IO.Compression.GzipStream]::New($is, [IO.Compression.CompressionMode]::Decompress); $r=[IO.StreamReader]::New($gs, [System.Text.Encoding]::UTF8); Set-Content \\\"C:\\Windows\\Temp\\setup.ps1\\\" $r.ReadToEnd(); $r.Close(); .\\\"C:\\Windows\\Temp\\setup.ps1\\\" "
}
SETTINGS
  depends_on = [azurerm_windows_virtual_machine.vm_domain_controller]
}

resource "azurerm_virtual_machine_extension" "deploy_open_ssh" {
  count = var.enable_open_ssh ? 1 : 0

  name                       = "${var.prefix}-deploy-open-ssh"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm_domain_controller.id
  publisher                  = "Microsoft.Azure.OpenSSH"
  type                       = "WindowsOpenSSH"
  type_handler_version       = "3.0"
  auto_upgrade_minor_version = false
  depends_on                 = [azurerm_virtual_machine_extension.create_active_directory_forest]
}

resource "time_sleep" "wait_400_seconds" {
  create_duration = "300s"
  depends_on      = [azurerm_virtual_machine_extension.deploy_open_ssh]
}

resource "null_resource" "update_user_attributes" {
  triggers = {
    #always_run = timestamp()
    host_ip = azurerm_windows_virtual_machine.vm_domain_controller.public_ip_address
  }
  provisioner "remote-exec" {
    connection {
      type     = "winrm"
      user     = var.vm_username
      password = var.vm_password
      host     = self.triggers.host_ip
      https    = false
      insecure = true
      port     = 5985
    }

    inline = [
      "powershell.exe -command \"${local.powershell_command}\" "
    ]
  }
  depends_on = [time_sleep.wait_400_seconds, azurerm_windows_virtual_machine.vm_domain_controller]
}
