terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.3.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "weka-images"
    storage_account_name = "sharedgallerybackend"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    subscription_id      = "d95fb89e-da05-41c6-8a66-3981e85ee1af"
  }

}