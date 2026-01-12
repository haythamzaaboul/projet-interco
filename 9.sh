#!/bin/bash
set -e

### 1) Interfaces
ip link set dev enp1s0f0 up
ip link set dev enp1s0f1 up

ip a a 120.0.65.1/24 dev enp1s0f0 || true
ip a a 120.0.66.1/24  dev enp1s0f1 || true

### 2) Routage IP
echo 1 > /proc/sys/net/ipv4/ip_forward


#### 3) Firewall (iptables)
# on laisse passer que les trafic allant/venant des reseaux connus
iptables -F FORWARD

iptables -P FORWARD DROP

# 120.0.65.0/24 vers 120.0.66.0/24
iptables -A FORWARD -s 120.0.65.0/24 -d 120.0.66.0/24 -j ACCEPT

# 120.0.64.0/24 vers 120.0.66.0/24
iptables -A FORWARD -s 120.0.64.0/24 -d 120.0.66.0/24 -j ACCEPT

# 120.0.66.0/24 vers 120.0.65.0/24
iptables -A FORWARD -s 120.0.66.0/24 -d 120.0.65.0/24 -j ACCEPT

# 120.0.66.0/24 vers 120.0.64.0/24
iptables -A FORWARD -s 120.0.66.0/24 -d 120.0.64.0/24 -j ACCEPT




### 4) DHCP (via dnsmasq)
# On suppose que dnsmasq est installé et utilisé pour le DHCP
cat >/etc/dnsmasq.d/lan-120-0-66.conf <<EOF
interface=enp1s0f1
dhcp-range=120.0.66.100,120.0.66.200,12h
dhcp-option=3,120.0.66.1       # passerelle par défaut
dhcp-option=6,120.0.64.3          # DNS 
EOF

systemctl restart dnsmasq


### 5) Quagga / OSPF
cp ./daemons /etc/quagga/daemons
chown quagga:quagga /etc/quagga/daemons
chmod 640 /etc/quagga/daemons
systemctl restart quagga

# Config OSPF
vtysh \
  -c "configure terminal" \
  -c "router ospf" \
  -c "ospf router-id 9.9.9.9" \
  -c "network 120.0.65.0/24 area 1" \
  -c "network 120.0.66.0/24 area 1" \
  -c "end" \
  -c "write"


ip route add default via 120.0.65.3