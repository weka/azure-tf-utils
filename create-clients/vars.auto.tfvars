rg_name            = "denise7"
clients_name       = "cl16"
clients_size       = 2
install_ofed       = false
install_dpdk       = true
subnets_name       = ["onesub-subnet-0"]
vnet_name          = "onesub-vnet"
sg_name            = "onesub-sg"
instance_type      = "Standard_L8s_v3"
backend_ip         = "20.124.26.83"
backend_private_ip = "10.0.2.1"
ssh_private_key    = "/tmp/onesub-l8-private-key.pem"
ssh_public_key     = "/tmp/onesub-l8-public-key.pub"
ppg_name           = "onesub-l8-backend-ppg"
custom_image_id    = "/subscriptions/d2f248b9-d054-477f-b7e8-413921532c2a/resourceGroups/weka-tf/providers/Microsoft.Compute/images/weka-custome-image-ofed-5.6-image"