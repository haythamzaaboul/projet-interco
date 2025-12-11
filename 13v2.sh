#!/bin/bash
set -e

# Mise en UP des interfaces
ip link set dev enp1s0f0 up
ip link set dev enp1s0f1 up
ip a a 120.0.65.3/24 dev enp1s0f0
ip a a 120.0.64.1/24 dev enp1s0f1

# Activer le routage IPv4
echo 1 > /proc/sys/net/ipv4/ip_forward

# Copier le fichier daemons
cp ./daemons /etc/quagga/daemons
chown quagga:quagga /etc/quagga/daemons
chmod 640 /etc/quagga/daemons

# Redémarrer Quagga
systemctl restart quagga

# Config OSPF SANS EXPECT
vtysh <<EOF
configure terminal
router ospf
 network 120.0.65.0/24 area 1
 network 120.0.64.0/24 area 2
 router-id 13.13.13.13
end
write
EOF
