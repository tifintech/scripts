GUEST_NAME=$1
CORE_COUNT=$2
RAM=$3
DISK_SIZE=$4

PUBLIC_IP=$5
GATEWAY=$6
PRIVATE_IP=$7

if [[ -z "$GUEST_NAME" ]]; then
   printf "Guest name missing\n"
   exit 1
fi

if [[ -z "$CORE_COUNT" ]]; then
   printf "Core count missing\n"
   exit 1
fi

if [[ -z "$RAM" ]]; then
   printf "Ram missing\n"
   exit 1
fi

if [[ -z "$DISK_SIZE" ]]; then
   printf "Disk size missing\n"
   exit 1
fi

if [[ -z "$PUBLIC_IP" ]]; then
   printf "Public IP missing\n"
   exit 1
fi

if [[ -z "$GATEWAY" ]]; then
   printf "Gateway missing\n"
   exit 1
fi

if [[ -z "$PRIVATE_IP" ]]; then
   printf "Private IP missing\n"
   exit 1
fi

CLOUD_IMAGE_NAME="focal-server-cloudimg-amd64.img"
CLOUD_BASE="http://cloud-images.ubuntu.com/focal/current"
CLOUD_IMAGE_LOCATION="${CLOUD_BASE}/${CLOUD_IMAGE_NAME}"

LOCAL_IMAGE_DIRECTORY="/var/lib/libvirt/images"
LOCAL_IMAGE_NAME="focal-20.04.qcow2"
LOCAL_IMAGE_PATH="${LOCAL_IMAGE_DIRECTORY}/${LOCAL_IMAGE_NAME}"

GUEST_IMAGE_DIRECTORY="${LOCAL_IMAGE_DIRECTORY}/$GUEST_NAME"
GUEST_IMAGE_GCOW_PATH="${GUEST_IMAGE_DIRECTORY}/hdd.qcow2"
GUEST_IMAGE_RAW_PATH="${GUEST_IMAGE_DIRECTORY}/hdd.raw"

GUEST_CI_IMAGE_PATH="${GUEST_IMAGE_DIRECTORY}/ci.img";

echo "Get cloud image"

if [ ! -f "$LOCAL_IMAGE_DIRECTORY" ]; then
sudo mkdir -p $LOCAL_IMAGE_DIRECTORY
wget $CLOUD_IMAGE_LOCATION
sudo mv $CLOUD_IMAGE_NAME $LOCAL_IMAGE_PATH
fi

echo "Create guest disk"
sudo mkdir -p $GUEST_IMAGE_DIRECTORY
sudo qemu-img create -f qcow2 -o backing_file=$LOCAL_IMAGE_PATH $GUEST_IMAGE_GCOW_PATH
sudo qemu-img resize $GUEST_IMAGE_GCOW_PATH ${DISK_SIZE}G
sudo qemu-img convert $GUEST_IMAGE_GCOW_PATH $GUEST_IMAGE_RAW_PATH
sudo rm -f $GUEST_IMAGE_GCOW_PATH

echo "Create cloud init files"
cat << EOF > /tmp/network.yaml
version: 2
ethernets:
  ens3:
    dhcp4: no
    addresses:
      - $PUBLIC_IP
    gateway4: $GATEWAY
    nameservers:
      addresses: [8.8.8.8, 8.8.4.4]
  ens4:
    dhcp4: no
    addresses:
      - $PRIVATE_IP
EOF

cat << EOF > /tmp/user.yaml
#cloud-config
user: root
chpasswd: {expire: false}
password: Password123
disable_root: false
ssh_pwauth: true
users:
    - name: tifintech
      ssh-authorized-keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAtduYq3Ca1r4p8eWI6apcmn5AgdpUJGvcthQohlaa0q257gVzfPpsxSTLLJ4rwKzOeUwnKqNCirDAiDA34zOIxKiTAYsw1u0ucxoR+/wZQxaQRFxOZdp9wGwTXxMxpLI10tfbr6zoxOGtOTfIgdTksakuSwFJDnRikxw2s28lIp+0EIOPrNpOx0dgRThrozyG6eZdtorOu74/yOQxBCOktx38JSlAvcpQiRSXFJvlL172IrVkJmx2I14/l9YVAKCK6p82Z6F1eelBEqzQifQQgmi4Hu439Cs8qriA0HiwwNBy6WW8F+MdF+BCwWBHiSRfxQf6OH4yGFVb6Pv4ew+A1Q==
      sudo: ['ALL=(ALL) NOPASSWD:ALL']
      groups: sudo
      shell: /bin/bash
final_message: "Cloud init complete."
EOF

echo "Create cloud init data"
sudo cloud-localds -v --network-config=/tmp/network.yaml $GUEST_CI_IMAGE_PATH /tmp/user.yaml /tmp/meta.yaml

rm -f /tmp/*.yaml

echo "Create VM"
sudo virt-install --connect qemu:///system --virt-type kvm --name $GUEST_NAME --cpu host --ram $RAM --vcpus=$CORES --os-type linux --os-variant ubuntu18.04 \
--disk path=${GUEST_IMAGE_RAW_PATH},format=raw,io=native,cache=none \
--disk path=${GUEST_CI_IMAGE_PATH},format=raw --import \
--network bridge=br0,model=virtio,mac=52:54:00:b2:cb:b0 \
--network bridge=br1,model=virtio \
--noautoconsole

sudo virsh autostart $GUEST_NAME
