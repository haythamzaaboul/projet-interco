#!/bin/bash
set -e

# Interfaces
ip link set dev enp1s0f0 up
ip link set dev enp1s0f1 up
ip a a 120.0.65.3/24 dev enp1s0f0 || true
ip a a 120.0.64.1/24 dev enp1s0f1 || true

# Routage
echo 1 > /proc/sys/net/ipv4/ip_forward

# daemons
cp ./daemons /etc/quagga/daemons
chown quagga:quagga /etc/quagga/daemons
chmod 640 /etc/quagga/daemons
systemctl restart quagga

# Config OSPF SANS vtysh interactif
vtysh \
  -c "configure terminal" \
  -c "router ospf" \
  -c "network 120.0.65.0/24 area 1" \
  -c "network 120.0.64.0/24 area 2" \
  -c "router-id 13.13.13.13" \
  -c "end" \
  -c "write"
