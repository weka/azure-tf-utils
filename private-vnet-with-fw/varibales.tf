variable "prefix" {
  type        = string
  description = ""
}

variable "location" {
  type    = string
  default = "West Europe"
}

variable "address_space" {
  default = "10.10.0.0/16"
}

variable "tags_map" {
  default = { "network" : "private" }
}

variable "public_address_prefixes" {
  default = "10.10.1.0/24"
}

variable "private_address_prefixes" {
  default = "10.10.2.0/24"
}

variable "address_prefixes_fw" {
  default = "10.10.0.0/26"
}

variable "vm_username" {
  default = "weka"
}

variable "source_image_id" {
  type        = string
  default     = "/communityGalleries/WekaIO-d7d3f308-d5a1-4c45-8e8a-818aed57375a/images/ubuntu20.04/versions/latest"
  description = "Use weka custom image, ubuntu 20.04 with kernel 5.4 and ofed 5.8-1.1.2.1"
}

variable "ssh_public_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC83xywjfh32vOUZGc2cWMBI7s0krK1au2EkWSTLkkOnsW7QVulrwqT5yi+02lVsJ7TPIV0DYTyg2GjkcUoBOyTu0/Msly9cTPv033SD+17CY3WAG29kY0OGkxSugpEWp4Z+vaQqGWP0G3D7yxBXQ0m0W3yDzNV+Jk3PERh4t7VU4T+zRmGy1cBttW1nQH9BewqgNfynQvUr3/YBkQXP0g2yTWtFM+0BUv4imcNpgm4/MQyQX41PJt0ey8v/pEuz9Hl75aZINwkdbQvSVWO2pcwwtkMtSK/89kYKCI3bF0gBSUPlnoPZorYyk+Y99nrOLUhSdrC8IjZ2DLQfzuwLNtl weka_id_rsa_2019.05.27"
}

variable "instance_type" {
  type        = string
  description = "The virtual machine type (sku) to deploy."
  default     = "Standard_DC2s_v2"
}

variable "subscription_id" {}

variable "function_app_subnet_delegation_cidr" {
  default = "10.0.3.0/25"
}

variable "logic_app_subnet_delegation_cidr" {
  default = "10.0.4.0/25"
}