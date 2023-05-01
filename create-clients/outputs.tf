output "cliets-ips-commands" {
  value = <<EOT
    az vmss list-instance-public-ips -g ${var.rg_name} --name ${local.vmss_name} --subscription ${var.subscription_id} --query "[].ipAddress"
EOT
}
