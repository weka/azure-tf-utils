variable "prefix" {
  type    = string
  default = "weka"
}

variable "subscription_id" {
  type    = string
  default = "d2f248b9-d054-477f-b7e8-413921532c2a"
}

variable "rg_name" {
  type        = string
  description = "The scope at which the RG applies to role"
}

variable "vnet_rg_name" {
  type        = string
  default     = ""
  description = "Resource group name of vnet"
}

variable "use_network" {
  type        = bool
  default     = false
  description = "Create custom role to allow read and use existing network"
}

variable "role_type" {
  type        = string
  default     = "all" # all for all weka deployment; essential for poc/demo
  description = "With role to create.  'all' - for all weka deployment; 'essential' - for poc"
}

variable "role_permission" {
  type = map(list(string))
  default = {
    allow_write_delete_network_permissions = [
      "Microsoft.Network/virtualNetworks/write",
      "Microsoft.Network/virtualNetworks/delete",
      "Microsoft.Network/virtualNetworks/join/action",
      "Microsoft.Network/virtualNetworks/subnets/write",
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/virtualNetworks/subnets/delete",
      "Microsoft.Network/networkSecurityGroups/write",
      "Microsoft.Network/networkSecurityGroups/join/action",
      "Microsoft.Network/networkSecurityGroups/securityRules/write",
      "Microsoft.Network/networkSecurityGroups/securityRules/delete",
      "Microsoft.Network/networkSecurityGroups/delete",
      "Microsoft.Network/publicIPAddresses/write",
      "Microsoft.Network/publicIPAddresses/delete",
      "Microsoft.Network/publicIPAddresses/join/action",
      "Microsoft.Network/networkInterfaces/write",
      "Microsoft.Network/networkInterfaces/join/action",
      "Microsoft.Network/networkInterfaces/delete",
      "Microsoft.Resources/subscriptions/resourceGroups/write"
    ]
    allow_read_network_permission = [
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/subnets/read",
      "Microsoft.Network/networkSecurityGroups/read",
      "Microsoft.Network/networkSecurityGroups/securityRules/read",
      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/networkInterfaces/join/action",
      "Microsoft.Network/networkInterfaces/delete",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/subscriptions/resourceGroups/write"
    ]
    essential = [
      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Network/publicIPAddresses/write",
      "Microsoft.Network/publicIPAddresses/delete",
      "Microsoft.Network/publicIPAddresses/join/action",
      "Microsoft.Compute/proximityPlacementGroups/*",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/networkInterfaces/write",
      "Microsoft.Network/networkInterfaces/join/action",
      "Microsoft.Network/networkInterfaces/delete",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/subscriptions/resourceGroups/write",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/write",
      "Microsoft.Compute/virtualMachines/delete",
      "Microsoft.Compute/virtualMachines/powerOff/action",
      "Microsoft.Compute/disks/read",
      "Microsoft.Compute/disks/write",
      "Microsoft.Compute/disks/delete"
    ]
    all = [
      "Microsoft.Network/privateDnsZones/*",
      "Microsoft.Network/privateDnsZones/virtualNetworkLinks/write",
      "Microsoft.Network/privateDnsZones/virtualNetworkLinks/delete",
      "Microsoft.Network/privateDnsZones/virtualNetworkLinks/read",
      "Microsoft.Network/privateDnsZones/SOA/*",
      "Microsoft.Network/privateDnsZones/A/read",
      "Microsoft.Network/privateDnsZones/A/write",
      "Microsoft.Network/privateDnsZones/A/delete",
      "Microsoft.Compute/proximityPlacementGroups/*",
      "Microsoft.Network/virtualNetworks/join/action", #
      "Microsoft.Network/virtualNetworks/subnets/join/action",#
      "Microsoft.Network/virtualNetworks/subnets/write",#
      "Microsoft.Network/virtualNetworks/subnets/delete",#
      "Microsoft.Network/networkSecurityGroups/join/action",#
      "Microsoft.Network/loadBalancers/read",
      "Microsoft.Network/loadBalancers/write",
      "Microsoft.Network/loadBalancers/delete",
      "Microsoft.Network/loadBalancers/health/action",
      "Microsoft.Network/loadBalancers/backendAddressPools/write",
      "Microsoft.Network/loadBalancers/backendAddressPools/delete",
      "Microsoft.Network/loadBalancers/backendAddressPools/join/action",
      "Microsoft.Network/loadBalancers/backendAddressPools/read",
      "Microsoft.Network/loadBalancers/probes/join/action",
      "Microsoft.KeyVault/vaults/read",
      "Microsoft.KeyVault/vaults/write",
      "Microsoft.KeyVault/vaults/delete",
      "Microsoft.KeyVault/vaults/secrets/read",
      "Microsoft.KeyVault/vaults/secrets/write",
      "Microsoft.KeyVault/vaults/accessPolicies/write",
      "Microsoft.KeyVault/locations/deletedVaults/purge/action",
      "Microsoft.Web/*",
      "microsoft.web/*",
      "Microsoft.Web/connections/Read",
      "Microsoft.Web/connections/Write",
      "Microsoft.Web/connections/Delete",
      "Microsoft.OperationalInsights/workspaces/write",
      "Microsoft.OperationalInsights/workspaces/read",
      "Microsoft.OperationalInsights/workspaces/delete",
      "Microsoft.Storage/storageAccounts/read",
      "Microsoft.Storage/storageAccounts/delete",
      "Microsoft.Storage/storageAccounts/write",
      "Microsoft.Storage/storageAccounts/blobServices/write",
      "Microsoft.Storage/storageAccounts/blobServices/read",
      "Microsoft.Storage/storageAccounts/listkeys/action",
      "Microsoft.Storage/storageAccounts/fileServices/read",
      "Microsoft.Compute/virtualMachineScaleSets/*",
      "Microsoft.Authorization/roleAssignments/read",
      "Microsoft.Authorization/roleAssignments/write",
      "Microsoft.Authorization/roleAssignments/delete",
      "Microsoft.Resources/deployments/read",
      "Microsoft.Resources/deployments/write",
      "Microsoft.Resources/deployments/delete",
      "Microsoft.Resources/deployments/exportTemplate/action",
      "Microsoft.Resources/deployments/validate/action",
      "Microsoft.Resources/deployments/operationstatuses/read",
      "Microsoft.Logic/workflows/read",
      "Microsoft.Logic/workflows/write",
      "Microsoft.Logic/workflows/delete",
      "Microsoft.Logic/workflows/providers/Microsoft.Insights/diagnosticSettings/read",
      "Microsoft.Logic/workflows/providers/Microsoft.Insights/diagnosticSettings/write",
      "Microsoft.Logic/workflows/providers/Microsoft.Insights/logDefinitions/read",
      "Microsoft.Logic/integrationAccounts/providers/Microsoft.Insights/logDefinitions/read",
      "Microsoft.Insights/*",
      "Microsoft.OperationalInsights/workspaces/providers/Microsoft.Insights/diagnosticSettings/Read",
      "Microsoft.OperationalInsights/workspaces/providers/Microsoft.Insights/diagnosticSettings/Write",
      "Microsoft.OperationalInsights/workspaces/sharedkeys/action",
      "Microsoft.AppConfiguration/configurationStores/providers/Microsoft.Insights/diagnosticSettings/read",
      "Microsoft.AppConfiguration/configurationStores/providers/Microsoft.Insights/diagnosticSettings/write"
    ]
  }
}