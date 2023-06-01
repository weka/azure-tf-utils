#!/bin/bash
set -ex

kernel_version=$(hostnamectl | grep Kernel | awk '{print $3}')
downgrade_kernel_version=5.4.0-1107

#Install new kernel version
apt search linux- | grep ${downgrade_kernel_version}-azure | grep -v 'linux-modules-nvidia\|linux-objects-nvidia\|signatures\|linux-modules-extra' | awk -F"/" '{print $1}' | xargs -I {} apt install -y {}

# Remove autoapprove ui
mv /usr/bin/linux-check-removal /usr/bin/linux-check-removal.orig
echo -e '#!/bin/sh\necho "Overriding default linux-check-removal script!"\nexit 0' | sudo tee /usr/bin/linux-check-removal
chmod +x /usr/bin/linux-check-removal

#Remove not relevant kernel version
dpkg -l | grep "linux\-[a-z]*\-" | grep ${kernel_version} | awk '{print $2}' | xargs -I {} apt --purge autoremove -y {}


