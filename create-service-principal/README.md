# Create service principal for TF weka deployment
Terraform to create custom role and service principal with password.

The outputs will display _client_secret_ and _client_id_, can be used as an input in other modules.

## Creating custom role to allow to create all resources (network, sg, subnets, vms):
- use_network need to set to *false*
 
## Creating custom role with exising network (network, sg, subnets):
- use_network need to set to *true*
- vnet_rg_name 

### Using service principa for Terraform deployment:
```hcl
provider "azurerm" {
  subscription_id = var.subscription_id
  partner_id      = "f13589d1-f10d-4c3b-ae42-3b1a8337eaf1"
  tenant_id       = "93ba0df2-e204-4bfc-99ef-cb9e273ce33f"
  client_id       = ""
  client_secret   = ""
  features {
  }
}
```