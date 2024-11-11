variable "prefix" {
  type    = string
  default = "ad-weka"
}

variable "subscription_id" {
}

variable "location" {
  type    = string
  default = "East US"
}

variable "address_space" {
  type    = string
  default = "10.100.0.0/16"
}

variable "address_prefix" {
  default = "10.100.100.0/24"
}

variable "vm_size" {
  default = "Standard_D2s_v3"
}
variable "vm_username" {
  default = "weka"
}

variable "vm_password" {
  default = "wekaIO.123!"
}

variable "active_directory_domain" {
  type        = string
  description = "The name of the Active Directory domain, for example `consoto.local`"
  default     = "ad.wekaio.lab"
}

variable "active_directory_netbios_name" {
  type        = string
  description = "The netbios name of the Active Directory domain, for example `consoto`"
  default     = "adwekaio"
}

#Password for the default domain admin
variable "domadminpassword" {
  type    = string
  default = "wekaIO.123!"
}

#Username for the default domain admin
variable "domadminuser" {
  type    = string
  default = "weka"
}

variable "windows_distribution_list" {
  description = "Pre-defined Azure Windows VM images list"
  type = map(object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  }))

  default = {
    windows2012r2dc = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2012-R2-Datacenter"
      version   = "latest"
    },

    windows2016dc = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2016-Datacenter"
      version   = "latest"
    },

    windows2019dc = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-Datacenter"
      version   = "latest"
    },
  }
}

variable "windows_distribution_name" {
  default = "windows2016dc"
}

variable "source_image_id" {
  default = null
}

variable "enable_public_ip_address" {
  default = true
}