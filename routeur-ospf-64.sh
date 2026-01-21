#!/bin/bash
set -e

### 1) Interfaces
ip link set dev enp1s0f0 up
ip link set dev enp1s0f1 up

# Interface vers le réseau 13 (120.0.64.0/24)
ip a a 120.0.64.2/24 dev enp1s0f0 || true

# Interface 2: up mais sans adresse IP
# enp1s0f1 est déjà up, pas d'adresse assignée

### 2) Routage IP
echo 1 > /proc/sys/net/ipv4/ip_forward

# Route par défaut vers le routeur 13
ip route add default via 120.0.64.1

### 3) Quagga / OSPF
cp ./daemons /etc/quagga/daemons
chown quagga:quagga /etc/quagga/daemons
chmod 640 /etc/quagga/daemons
systemctl restart quagga

# Config OSPF
vtysh \
  -c "configure terminal" \
  -c "router ospf" \
  -c "ospf router-id 14.14.14.14" \
  -c "network 120.0.64.0/24 area 2" \
  -c "end" \
  -c "write"
