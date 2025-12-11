sudo su //
ip link set dev enp1s0f0 up //
ip a //
ip a add 192.168.1.1/21 dev enp1s0f0 //
ip a //
echo 1 > /proc/sys/net/ipv4/ip_forward //
ip link set dev enp1s0f1 up //
ip a //
ip a add 120.0.64.5/24 dev enp1s0f1 //
i pa //
ping 120.0.64.4 -c 15 //
sudo iptables -t nat -A POSTROUTING -o enp1s0f1 -j MASQUERADE //
vim /etc/dnsmasq.conf //
systemctl restart dnsmasq //
iptables -t nat -L -n //


### Dans le fichier dnsmasq.conf :
interface enp1s0f0 //
dhcp-range=192.168.1.50,192.168.1.150,12h //
dhcp-option=3,192.168.1.1 //
dhcp-option=6,1.1.1.1,8.8.8.8 //
