PUBLIC_IP=$1
GATEWAY=$2
PRIVATE_IP=$3

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

echo "Configure bridge"
sudo bash -c 'cat > /etc/netplan/01-netcfg.yaml'
network:
  version: 2
  renderer: networkd
  ethernets:
    eno5:
      dhcp4: no
      dhcp6: no
    eno6:
      dhcp4: no
      mtu: 9000
  
  bridges:
    br0:
      interfaces: [eno5]
      dhcp4: no
      dhcp6: no
      addresses: [$PUBLIC_IP]
      gateway4: $GATEWAY
      nameservers:
        search: [dedi.leaseweb.net]
        addresses: [23.19.53.53,23.19.52.52]
    br1:
      interfaces: [eno6]
      dhcp4: no
      addresses: [$PRIVATE_IP]
EOF
