provider "azurerm" {
  subscription_id = "d95fb89e-da05-41c6-8a66-3981e85ee1af"
  features {
  }
}

resource "azurerm_shared_image_gallery" "gallery" {
  name                = "WekaSharedGallery"
  resource_group_name = var.rg_shared_name
  location            = var.location
  description         = "Shared weka images"
  sharing {
    permission = "Community"
    community_gallery {
      eula            = "www.weka.io"
      prefix          = "WekaIO"
      publisher_email = "denise@weka.io"
      publisher_uri   = "www.weka.io"
    }
  }
}

resource "azurerm_shared_image" "image" {
  name                                = "weka_custom_image"
  gallery_name                        = azurerm_shared_image_gallery.gallery.name
  resource_group_name                 = var.rg_shared_name
  location                            = var.location
  accelerated_network_support_enabled = true
  architecture                        = "x64"
  os_type                             = "Linux"
  hyper_v_generation                  = "V2"


  description = "Ubuntu 20.04 LTS Weka custom image definition"
  identifier {
    offer     = "WekaUbuntu"
    publisher = "WekaIO"
    sku       = "20.04"
  }
}

resource "azurerm_shared_image" "image_arm" {
  name                                = "weka_custom_image_arm"
  gallery_name                        = azurerm_shared_image_gallery.gallery.name
  resource_group_name                 = var.rg_shared_name
  location                            = var.location
  accelerated_network_support_enabled = true
  architecture                        = "Arm64"
  os_type                             = "Linux"
  hyper_v_generation                  = "V2"


  description = "Ubuntu 20.04 LTS Weka custom image definition"
  identifier {
    offer     = "WekaUbuntu"
    publisher = "WekaIO"
    sku       = "arm"
  }
}

