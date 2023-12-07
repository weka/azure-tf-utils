variable "subscription_id" {}

module "private_vnet_with_fw" {
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