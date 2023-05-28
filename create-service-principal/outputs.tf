output "client_secret" {
  value = nonsensitive(azuread_service_principal_password.sp_password.value)
}

output "client_id" {
  value = azuread_application.app.application_id
}

output "tenant_id" {
  value = data.azuread_client_config.current.tenant_id
}