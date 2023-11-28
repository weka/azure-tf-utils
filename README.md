# azure-tf-utils
azure terrafrom utils

### Create Custom image:

Custom image will create on RND subscription, please use packer sp secrets  
https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/8e3799f8-8d44-4448-9980-836a7dc47880
```hcl
export SUBSCRIPTION_ID=d95fb89e-da05-41c6-8a66-3981e85ee1af
export CLIENT_ID=8e3799f8-8d44-4448-9980-836a7dc47880
export CLIENT_SECRET=""
export TENANT_ID=93ba0df2-e204-4bfc-99ef-cb9e273ce33f
export IMAGE_RG_NAME=weka-images
export TOKEN=""
```

### To create new version of gallery image as public image run:
change version var `image_version` to new version ( it will as latest version)

run: `packer build shared_ubuntu20.json`

### Build image for testing 
change version var `image_version` to new version ( it will as latest version)
chnage version var `weka_version`
run: `packer build testing_ubuntu20.json`


### Create AD domain
TF_VAR_subscription_id=<subscription-id> TF_VAR_module_name=ad terraform init
TF_VAR_subscription_id=<subscription-id> TF_VAR_module_name=ad terraform apply


#### Creating private network with FW:
Notion link https://www.notion.so/wekaio/Private-network-with-FW-dc661cc832444145b326581b3bae5f4a
```
TF_VAR_subscription_id=<subscription-id> TF_VAR_module_name=network_fw terraform init
TF_VAR_subscription_id=<subscription-id> TF_VAR_module_name=network_fw terraform apply
```
