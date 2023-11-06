# azure-tf-utils
azure terrafrom utils

### Create Custom image:

Custom image will create on RND subscription, please use packer sp secrets  
```hcl
export SUBSCRIPTION_ID=d95fb89e-da05-41c6-8a66-3981e85ee1af
export CLIENT_ID=8e3799f8-8d44-4448-9980-836a7dc47880
export CLIENT_SECRET=""
export TENANT_ID=93ba0df2-e204-4bfc-99ef-cb9e273ce33f
export IMAGE_RG_NAME=weka-images
export TOKEN=""
```

### To create only image run:
change image name `managed_image_name`

run: `packer build ubuntu20.json`

### To create new version of gallery image as public image run:
change version var `image_version` to new version ( it will as latest version)

run: `packer build shared_ubuntu20.json`