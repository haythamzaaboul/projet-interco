#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <domaine> <ip_serveur_web>"
    exit 1
fi

DOMAIN="$1"
WEB_IP="$2"
ZONE_FILE="/etc/bind/db.$DOMAIN"

echo "[*] Domaine : $DOMAIN"
echo "[*] Adresse IP du serveur web : $WEB_IP"

if ! dpkg -l | grep -q "^ii  bind9"; then
    echo "[!] Bind9 non installé. Installation..."
    apt update && apt install -y bind9 bind9utils bind9-doc
else
    echo "[✓] Bind9 déjà installé."
fi

if ! grep -q "$DOMAIN" /etc/bind/named.conf.local; then
    cat <<EOF >> /etc/bind/named.conf.local

zone "$DOMAIN" {
    type master;
    file "$ZONE_FILE";
};
EOF
    echo "[✓] Zone ajoutée dans named.conf.local"
else
    echo "[✓] Zone déjà présente dans named.conf.local"
fi

if [ ! -f "$ZONE_FILE" ]; then
    cat <<EOF > "$ZONE_FILE"
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN. admin.$DOMAIN. (
                          1
                     604800
                      86400
                    2419200
                     604800 )
        IN      NS      ns1.$DOMAIN.
ns1     IN      A       $WEB_IP
www     IN      A       $WEB_IP
EOF
else
    sed -i "/www/d" "$ZONE_FILE"
    sed -i "/ns1/d" "$ZONE_FILE"
    echo "ns1     IN      A       $WEB_IP" >> "$ZONE_FILE"
    echo "www     IN      A       $WEB_IP" >> "$ZONE_FILE"
    NEW_SERIAL=$(date +%Y%m%d%H)
    sed -i "s/[0-9]\+ *; Serial/$NEW_SERIAL ; Serial/" "$ZONE_FILE"
fi

named-checkconf
named-checkzone "$DOMAIN" "$ZONE_FILE"

systemctl restart named
systemctl enable named
systemctl restart bind9
systemctl enable bind9

echo "[✓] DNS configuré avec succès !"
echo "→ Domaine : $DOMAIN"
echo "→ ns1.$DOMAIN → $WEB_IP"
echo "→ www.$DOMAIN → $WEB_IP"
