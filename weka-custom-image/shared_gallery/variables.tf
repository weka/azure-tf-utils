variable "location" {
  type        = string
  default     = "eastus"
  description = "The Azure Region in which all resources in this example should be created."
}

variable "rg_shared_name" {
  type        = string
  default     = "weka-images"
  description = "Name of the Resource group in which to deploy shared resources"
}

variable "gallery_name" {
  type    = string
  default = "WekaComputeGallery"
}