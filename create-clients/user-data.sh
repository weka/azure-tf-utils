#!/bin/bash
set -ex

while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
   sleep 2
done
apt install net-tools -y

INSTALLATION_PATH="/tmp/weka"
mkdir -p $INSTALLATION_PATH

# install ofed
if [[ ${install_ofed} == true ]]; then
  OFED_NAME=ofed-${ofed_version}
  wget http://content.mellanox.com/ofed/MLNX_OFED-${ofed_version}/MLNX_OFED_LINUX-${ofed_version}-ubuntu18.04-x86_64.tgz -O $INSTALLATION_PATH/$OFED_NAME.tgz
  tar xf $INSTALLATION_PATH/$OFED_NAME.tgz --directory $INSTALLATION_PATH --one-top-level=$OFED_NAME
  cd $INSTALLATION_PATH/$OFED_NAME/*/
  ./mlnxofedinstall --without-fw-update --add-kernel-support --force 2>&1 | tee /tmp/weka_ofed_installation
  /etc/init.d/openibd restart

fi


for(( i=0; i<${nics_num}; i++ )); do
    cat <<-EOF | sed -i "/        eth$i/r /dev/stdin" /etc/netplan/50-cloud-init.yaml
            mtu: 3900
EOF
done

# config network with multi nics
if [[ ${install_dpdk} == true ]]; then
  for(( i=0; i<${nics_num}; i++)); do
    echo "20$i eth$i-rt" >> /etc/iproute2/rt_tables
  done

  echo "network:"> /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
  echo "  config: disabled" >> /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
  gateway=$(ip r | grep default | awk '{print $3}')
  for(( i=0; i<${nics_num}; i++ )); do
    eth=$(ifconfig | grep eth$i -C2 | grep 'inet ' | awk '{print $2}')
    cat <<-EOF | sed -i "/            set-name: eth$i/r /dev/stdin" /etc/netplan/50-cloud-init.yaml
            routes:
             - to: ${subnet_range}
               via: $gateway
               metric: 200
               table: 20$i
             - to: 0.0.0.0/0
               via: $gateway
               table: 20$i
            routing-policy:
             - from: $eth/32
               table: 20$i
             - to: $eth/32
               table: 20$i
EOF
  done
fi

netplan apply

apt update -y
apt install -y jq
apt install -y fio

rm -rf $INSTALLATION_PATH

# install weka
curl https://${token}@get.weka.io/dist/v1/install/4.2.0.86-beta/4.2.0.86-beta | sh

# mount client
function getNetStrForDpdk() {
  i=$1
  j=$2
  gateways=$3
  subnets=$4

  if [ -n "$gateways" ]; then #azure and gcp
    gateways=($gateways)
  fi

  if [ -n "$subnets" ]; then #azure only
    subnets=($subnets)
  fi

  net=" "
  for ((i; i<$j; i++)); do
    if [ -n "$subnets" ]; then
      subnet=$${subnets[$i]}
      subnet_inet=$(curl -s -H Metadata:true –noproxy “*” http://169.254.169.254/metadata/instance/network\?api-version\=2021-02-01 | jq --arg subnet "$subnet" '.interface[] | select(.ipv4.subnet[0].address==$subnet)' | jq -r .ipv4.ipAddress[0].privateIpAddress)
      eth=$(ifconfig | grep -B 1 $subnet_inet |  head -n 1 | cut -d ':' -f1)
    else
      eth=eth$i
      subnet_inet=$(ifconfig $eth | grep 'inet ' | awk '{print $2}')
    fi
    if [ -z $subnet_inet ];then
      net=""
      break
    fi
    enp=$(ls -l /sys/class/net/$eth/ | grep lower | awk -F"_" '{print $2}' | awk '{print $1}') #for azure
    if [ -z $enp ];then
      enp=$eth
    fi
    bits=$(ip -o -f inet addr show $eth | awk '{print $4}')
    IFS='/' read -ra netmask <<< "$bits"

    if [ -n "$gateways" ]; then
      gateway=$${gateways[$i]}
      net="$net -o net=$enp/$subnet_inet/$${netmask[1]}/$gateway"
    else
      net="$net -o net=$eth" #aws
    fi
  done
}

FILESYSTEM_NAME=default # replace with a different filesystem at need
MOUNT_POINT=/mnt/weka # replace with a different mount point at need
mkdir -p $MOUNT_POINT

weka local stop
weka local rm default --force
weka local stop && weka local rm -f --all

gateways="10.0.2.1 10.0.3.1 10.0.4.1 10.0.5.1"
subnets="10.0.2.0 10.0.3.0 10.0.4.0 10.0.5.0"
eth0=$(ifconfig | grep eth0 -C2 | grep 'inet ' | awk '{print $2}')
if [[ ${install_dpdk} == true ]]; then
  getNetStrForDpdk 2 3 "$gateways" "$subnets"
  mount -t wekafs $net -o num_cores=1 -o mgmt_ip=$eth0 ${backend_ip}/$FILESYSTEM_NAME $MOUNT_POINT
else
  mount -t wekafs -o net=udp ${backend_ip}/$FILESYSTEM_NAME $MOUNT_POINT
fi