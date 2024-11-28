provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

/***********************************
      AD Domain
***********************************/
module "create_ad_domain" {
  count                         = var.module_name == "ad" ? 1 : 0
  source                        = "./ad-domain"
  prefix                        = "ad-domain"
  subscription_id               = var.subscription_id
  location                      = "East US"
  vm_size                       = "Standard_D2s_v3"
  vm_username                   = "weka"
  vm_password                   = "<vm_password>"
  active_directory_domain       = "ad.wekaio.lab"
  active_directory_netbios_name = "adwekaio"
  domadminpassword              = "<vm_password>"
  windows_distribution_name     = "windows2019dc"
}

output "ad_domain_output" {
  value = module.create_ad_domain
}

module "private_vnet_with_fw" {
  count                               = var.module_name == "network_fw" ? 1 : 0
  source                              = "./private-vnet-with-fw"
  prefix                              = "private"
  location                            = "East US"
  subscription_id                     = var.subscription_id
  address_space                       = "10.0.0.0/16"
  public_address_prefixes             = "10.0.0.0/24"
  private_address_prefixes            = "10.0.1.0/24"
  address_prefixes_fw                 = "10.0.2.0/26"
  function_app_subnet_delegation_cidr = "10.0.3.0/25"
  logic_app_subnet_delegation_cidr    = "10.0.4.0/25"
}

output "private_vnet" {
  value = module.private_vnet_with_fw
}