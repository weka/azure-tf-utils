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