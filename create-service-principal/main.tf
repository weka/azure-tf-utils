provider "azurerm" {
  subscription_id = var.subscription_id
  partner_id      = "f13589d1-f10d-4c3b-ae42-3b1a8337eaf1"
  features {
  }
}

data "azuread_client_config" "current" {}

data "azurerm_subscription" "primary" {}

locals {
  custom_role_definitions = {
    "${local.role_name}" = {
      description = "Custom Role to allow create weka resources under resource group ${var.rg_name}"
      scope       = local.scope
      permissions = {
        actions        = local.actions,
        notActions     = [],
        dataActions    = [],
        notDataActions = []
      }
      assignable_scopes = local.assignable_scopes
    }
  }
  role_name         = "${var.role_type}_${var.prefix}_custom_role"
  vnet_permission   = var.use_network == true ? var.role_permission.allow_read_network_permission : concat(var.role_permission.allow_write_delete_network_permissions, var.role_permission.allow_read_network_permission)
  actions           = var.role_type == "all" ? concat(local.vnet_permission, var.role_permission.all) : concat(local.vnet_permission, var.role_permission.essential)
  scope             = var.use_network == true ? data.azurerm_subscription.primary.id : "${data.azurerm_subscription.primary.id}/resourceGroups/${var.rg_name}"
  assignable_scopes = var.use_network == true && var.vnet_rg_name != "" ? ["${data.azurerm_subscription.primary.id}/resourceGroups/${var.rg_name}", "${data.azurerm_subscription.primary.id}/resourceGroups/${var.vnet_rg_name}"] : ["${data.azurerm_subscription.primary.id}/resourceGroups/${var.rg_name}"]
}

resource "azuread_application" "app" {
  display_name = "${var.prefix}-app"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "sp" {
  application_id = azuread_application.app.application_id
  owners         = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "sp_password" {
  service_principal_id = azuread_service_principal.sp.object_id
}

resource "azurerm_role_definition" "custom_role" {
  name        = local.role_name
  scope       = local.custom_role_definitions[local.role_name]["scope"]
  description = local.custom_role_definitions[local.role_name]["description"]

  permissions {
    actions          = lookup(local.custom_role_definitions[local.role_name]["permissions"], "actions", [])
    not_actions      = lookup(local.custom_role_definitions[local.role_name]["permissions"], "notActions", [])
    data_actions     = lookup(local.custom_role_definitions[local.role_name]["permissions"], "dataActions", [])
    not_data_actions = lookup(local.custom_role_definitions[local.role_name]["permissions"], "notDataActions", [])
  }
  assignable_scopes = lookup(local.custom_role_definitions[local.role_name]["permissions"], "assignable_scopes", [])
}

resource "azurerm_role_assignment" "role_assignment" {
  principal_id       = azuread_service_principal.sp.object_id
  role_definition_id = azurerm_role_definition.custom_role.role_definition_resource_id
  scope              = "${data.azurerm_subscription.primary.id}/resourceGroups/${var.rg_name}"
  depends_on         = [azurerm_role_definition.custom_role]
}


resource "azurerm_role_assignment" "role_assignment_to_vnet_rg" {
  count              = var.vnet_rg_name != "" ? 1 : 0
  principal_id       = azuread_service_principal.sp.object_id
  scope              = "${data.azurerm_subscription.primary.id}/resourceGroups/${var.vnet_rg_name}"
  role_definition_id = azurerm_role_definition.custom_role.role_definition_resource_id
  depends_on         = [azurerm_role_definition.custom_role]
}