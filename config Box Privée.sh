#!/bin/bash
set -e

### 1) Interfaces
# Activation des interfaces
ip link set dev enp1s0f0 up
ip link set dev enp1s0f1 up

# Configuration des adresses IP
# enp1s0f0 = LAN (192.168.1.1/21)
# enp1s0f1 = WAN (120.0.64.5/24)
ip a a 192.168.1.1/21 dev enp1s0f0 || true
ip a a 120.0.64.5/24 dev enp1s0f1 || true

### 2) Routage IP
# Activation du transfert de paquets au niveau du noyau
echo 1 > /proc/sys/net/ipv4/ip_forward

### 3) NAT (iptables)
# On fait du masquerading pour que le LAN 192.168.0.0/21 sorte via le WAN (enp1s0f1)
iptables -t nat -A POSTROUTING -s 192.168.0.0/21 -o enp1s0f1 -j MASQUERADE

# Autoriser le trafic LAN -> WAN
iptables -A FORWARD -i enp1s0f0 -o enp1s0f1 -s 192.168.0.0/21 -j ACCEPT

# Autoriser les réponses WAN -> LAN (trafic déjà établi)
iptables -A FORWARD -i enp1s0f1 -o enp1s0f0 -m state --state ESTABLISHED,RELATED -j ACCEPT


### 4) DHCP (via dnsmasq)
# Configuration spécifique pour le segment LAN sur enp1s0f0
cat >/etc/dnsmasq.d/lan-192-168-1.conf <<EOF
interface=enp1s0f0
dhcp-range=192.168.1.50,192.168.1.150,12h
dhcp-option=3,192.168.1.1        # Passerelle par défaut (ce routeur)
dhcp-option=6,1.1.1.1,8.8.8.8    # DNS Cloudflare et Google
EOF

systemctl restart dnsmasq


### 5) Quagga / OSPF
# Préparation des droits et des démons
if [ -f "./daemons" ]; then
    cp ./daemons /etc/quagga/daemons
    chown quagga:quagga /etc/quagga/daemons
    chmod 640 /etc/quagga/daemons
    systemctl restart quagga
fi

# Configuration OSPF via vtysh
vtysh \
  -c "configure terminal" \
  -c "router ospf" \
  -c "network 120.0.64.0/24 area 1" \
  -c "network 192.168.0.0/21 area 1" \
  -c "router-id 10.10.10.10" \
  -c "end" \
  -c "write"

# Route par défaut vers la passerelle distante
ip route add default via 120.0.64.4 || true

echo "Configuration réseau et routage terminée."
