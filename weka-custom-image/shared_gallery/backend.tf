terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.1.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "weka-images"
    storage_account_name = "sharedgallerybackend"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }

}