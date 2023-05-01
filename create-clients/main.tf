provider "azurerm" {
  features {}
  subscription_id   = var.subscription_id
}

data azurerm_resource_group "rg"{
  name = var.rg_name
}

data "azurerm_virtual_network" "vnet" {
  name = var.vnet_name
  resource_group_name = var.rg_name
}

data "azurerm_subnet" "subnets" {
  count                = length(var.subnets_name)
  resource_group_name  = var.rg_name
  virtual_network_name = var.vnet_name
  name                 = var.subnets_name[count.index]
}

data "azurerm_network_security_group" "sg_id" {
  name = var.sg_name
  resource_group_name = var.rg_name
}

# ===================== SSH key ++++++++++++++++++++++++= #
resource "tls_private_key" "ssh_key" {
  count     = var.ssh_public_key == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "public_key" {
  count           = var.ssh_public_key == null ? 1 : 0
  content         = tls_private_key.ssh_key[count.index].public_key_openssh
  filename        = "${local.ssh_path}-client-public-key.pub"
  file_permission = "0600"
}

resource "local_file" "private_key" {
  count           = var.ssh_public_key == null ? 1 : 0
  content         = tls_private_key.ssh_key[count.index].private_key_pem
  filename        = "${local.ssh_path}-client-private-key.pem"
  file_permission = "0600"
}

locals {
  ssh_path                  = "/tmp/${var.prefix}-${var.clients_name}"
  public_ssh_key            = var.ssh_public_key == null ? tls_private_key.ssh_key[0].public_key_openssh : file(var.ssh_public_key)
  private_ssh_key           = var.ssh_private_key == null ? tls_private_key.ssh_key[0].private_key_pem : file(var.ssh_private_key)
  alphanumeric_prefix_name  = lower(replace(var.prefix,"/\\W|_|\\s/",""))
  nics_number               = 2
  netmask                   = split("/",data.azurerm_subnet.subnets[0].address_prefix)[1]
  vmss_name                 = var.custom_image_id != null ? azurerm_linux_virtual_machine_scale_set.custom_image_vmss[0].name : azurerm_linux_virtual_machine_scale_set.default_image_vmss[0].name

}

data "template_file" "init" {
  template = file("${path.module}/user-data.sh")
  vars = {
    private_ssh_key = local.private_ssh_key
    ofed_version    = var.ofed_version
    install_ofed    = var.install_ofed
    weka_version    = var.weka_version
    backend_ip      = var.backend_ip
    install_dpdk    = var.install_dpdk
    nics_num        = local.nics_number
    netmask         = local.netmask
    subnet_range    = data.azurerm_subnet.subnets[0].address_prefix
    token           = var.get_weka_io_token
  }
}

data "template_cloudinit_config" "cloud_init" {
  gzip          = false
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.init.rendered
  }
}

resource "azurerm_proximity_placement_group" "ppg" {
  name                = "${var.prefix}-${var.clients_name}-clients-ppg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = var.rg_name
  tags                = merge({"weka_cluster": var.clients_name})
}

resource "azurerm_linux_virtual_machine_scale_set" "custom_image_vmss" {
  count                           = var.custom_image_id != null ? 1 : 0
  name                            = "${var.prefix}-${var.clients_name}-clients-vmss"
  location                        = data.azurerm_resource_group.rg.location
  resource_group_name             = var.rg_name
  sku                             = var.instance_type
  upgrade_mode                    = "Manual"
  #health_probe_id                 = azurerm_lb_probe.backend_lb_probe.id
  admin_username                  = var.vm_username
  instances                       = var.clients_size
  computer_name_prefix            = "${var.prefix}-${var.clients_name}-client-vmss"
  custom_data                     = base64encode(data.template_file.init.rendered)
  disable_password_authentication = true
  proximity_placement_group_id    = azurerm_proximity_placement_group.ppg.id
  tags                            = merge( {"weka_cluster": var.clients_name})
  source_image_id                 = var.custom_image_id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  admin_ssh_key {
    username   = var.vm_username
    public_key = local.public_ssh_key
  }

  identity {
    type = "SystemAssigned"
  }

  dynamic "network_interface" {
    for_each = range(0,1)
    content {
      name                      = "${var.prefix}-${var.clients_name}-client-nic"
      network_security_group_id = data.azurerm_network_security_group.sg_id.id
      primary                   = true
      enable_accelerated_networking = true
      ip_configuration {
        primary                                = true
        name                                   = "ipconfig1"
        subnet_id                              = data.azurerm_subnet.subnets[0].id
        #load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.lb_backend_pool.id]
        public_ip_address {
          name = "${var.prefix}-${var.clients_name}-public-ip"
        }
      }
    }
  }
  dynamic "network_interface" {
    for_each = range(1, local.nics_number)
    content {
      name                      = "${var.prefix}-${var.clients_name}-client-nic-${network_interface.value}"
      network_security_group_id = data.azurerm_network_security_group.sg_id.id
      primary                   = false
      enable_accelerated_networking = true
      ip_configuration {
        primary                                = true
        name                                   = "ipconfig-${network_interface.value}"
        subnet_id                              = data.azurerm_subnet.subnets[0].id
       # load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.lb_backend_pool.id]
      }
    }
  }
  lifecycle {
    ignore_changes = [ instances, custom_data ]
  }
  #depends_on = [azurerm_lb_backend_address_pool.lb_backend_pool,azurerm_lb_probe.backend_lb_probe,azurerm_proximity_placement_group.ppg, azurerm_lb_rule.backend_lb_rule, azurerm_lb_rule.ui_lb_rule]
}


resource "azurerm_linux_virtual_machine_scale_set" "default_image_vmss" {
  count                           = var.custom_image_id == null ? 1 : 0
  name                            = "${var.prefix}-${var.clients_name}-clients-vmss"
  location                        = data.azurerm_resource_group.rg.location
  resource_group_name             = var.rg_name
  sku                             = var.instance_type
  upgrade_mode                    = "Manual"
 # health_probe_id                 = azurerm_lb_probe.backend_lb_probe.id
  admin_username                  = var.vm_username
  instances                       = var.clients_size
  computer_name_prefix            = "${var.prefix}-${var.clients_name}-client"
  custom_data                     = base64encode(data.template_file.init.rendered)
  disable_password_authentication = true
  proximity_placement_group_id    = azurerm_proximity_placement_group.ppg.id
  tags                            = merge({"weka_cluster": var.clients_name})
  source_image_reference {
    offer     = lookup(var.linux_vm_image, "offer", null)
    publisher = lookup(var.linux_vm_image, "publisher", null)
    sku       = lookup(var.linux_vm_image, "sku", null)
    version   = lookup(var.linux_vm_image, "version", null)
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  admin_ssh_key {
    username   = var.vm_username
    public_key = local.public_ssh_key
  }

  identity {
    type = "SystemAssigned"
  }

  dynamic "network_interface" {
    for_each = range(0,1)
    content {
      name                          = "${var.prefix}-${var.clients_name}-client-nic"
      network_security_group_id     = data.azurerm_network_security_group.sg_id.id
      primary                       = true
      enable_accelerated_networking = var.install_dpdk
      ip_configuration {
        primary                                = true
        name                                   = "ipconfig1"
        subnet_id                              = data.azurerm_subnet.subnets[0].id
       # load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.lb_backend_pool.id]
        public_ip_address {
          name = "${var.prefix}-${var.clients_name}-public-ip"
        }
      }
    }
  }
  dynamic "network_interface" {
    for_each = range(1,local.nics_number)
    content {
      name                          = "${var.prefix}-${var.clients_name}-clients-nic-${network_interface.value}"
      network_security_group_id     = data.azurerm_network_security_group.sg_id.id
      primary                       = false
      enable_accelerated_networking = var.install_dpdk

      ip_configuration {
        primary                                = true
        name                                   = "ipconfig-${network_interface.value}"
        subnet_id                              = data.azurerm_subnet.subnets[0].id
       # load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.lb_backend_pool.id]
      }
    }
  }
  lifecycle {
    ignore_changes = [ instances, custom_data ]
  }
}

resource "null_resource" "force-delete-vmss" {
  triggers = {
    vmss_name       = var.custom_image_id != null ? azurerm_linux_virtual_machine_scale_set.custom_image_vmss[0].name : azurerm_linux_virtual_machine_scale_set.default_image_vmss[0].name
    rg_name         = data.azurerm_resource_group.rg.name
    subscription_id = var.subscription_id
  }
  provisioner "local-exec" {
    when = destroy
    command = "az vmss delete --name ${self.triggers.vmss_name} --resource-group ${self.triggers.rg_name} --force-deletion true --subscription ${self.triggers.subscription_id}"
  }
  depends_on = [azurerm_linux_virtual_machine_scale_set.default_image_vmss, azurerm_linux_virtual_machine_scale_set.custom_image_vmss]
}
