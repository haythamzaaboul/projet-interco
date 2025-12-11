ip link set dev enp1s0f0 up
ip link set dev enp1s0f1 up
ip a a 120.0.65.3/24 dev enp1s0f0
ip a a 120.0.64.1/24 dev enp1s0f1
echo 1 > /proc/sys/net/ipv4/ip_forward
sudo cp ./daemons /etc/quagga/daemons
sudo chown quagga:quagga /etc/quagga/daemons
sudo chmod 640 /etc/quagga/daemons
systemctl restart quagga

PASSWORD="zebra"

expect <<EOF
set timeout 10
spawn telnet localhost ospf
# Attendre la demande de mot de passe
expect "Password:"
send "$PASSWORD\r"

# On est maintenant dans ospfd (invite 'ospfd>')
expect "ospfd>"
send "en\r"

# Passer en mode configuration
expect "ospfd#"
send "conf t\r"

# Mode configuration OSPF
expect "ospfd(config)#"
send "router ospf\r"

expect "ospfd(config-router)#"
send "network 120.0.65.0/24 area 1\r"


expect "ospfd(config-router)#"
send "network 120.0.64.0/24 area 2\r"


expect "ospfd(config-router)#"
send "router-id 13.13.13.13\r"

# Sortie des modes de config
expect "ospfd(config-router)#"
send "exit\r"

expect "ospfd(config)#"
send "exit\r"

# Sauvegarder la config
expect "ospfd#"
send "write\r"

# Quitter le daemon
expect "ospfd#"
send "exit\r"

expect eof
EOF
