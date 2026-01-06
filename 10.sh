#!/bin/bash
set -e

### 1) Interfaces
ip link set dev enp1s0f0 up
ip link set dev enp1s0f1 up

ip a a 120.0.65.2/24 dev enp1s0f0 || true
ip a a 192.168.3.1/24  dev enp1s0f1 || true

### 2) Routage IP
echo 1 > /proc/sys/net/ipv4/ip_forward

### 3) NAT (iptables)
# On fait du masquerading pour que le LAN 192.168.3.0/24 sorte via enp1s0f0
iptables -t nat -A POSTROUTING -s 192.168.3.0/24 -o enp1s0f0 -j MASQUERADE

# Autoriser le trafic LAN -> WAN
iptables -A FORWARD -i enp1s0f1 -o enp1s0f0 -s 192.168.3.0/24 -j ACCEPT

# Autoriser les réponses WAN -> LAN
iptables -A FORWARD -i enp1s0f0 -o enp1s0f1 -m state --state ESTABLISHED,RELATED -j ACCEPT


### 4) DHCP (via dnsmasq)
# On suppose que dnsmasq est installé et utilisé pour le DHCP
cat >/etc/dnsmasq.d/lan-192-168-3.conf <<EOF
interface=enp1s0f1
dhcp-range=192.168.3.100,192.168.3.200,12h
dhcp-option=3,192.168.3.1       # passerelle par défaut
dhcp-option=6,8.8.8.8           # DNS (Google ici)
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
  -c "network 120.0.65.0/24 area 1" \
  -c "network 192.168.3.0/24 area 1" \
  -c "router-id 10.10.10.10" \
  -c "end" \
  -c "write"

ip route add default via 120.0.65.3