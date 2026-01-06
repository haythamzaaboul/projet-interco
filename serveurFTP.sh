#!/bin/bash
set -e

### 0) Variables à adapter si besoin
USB_DIR="/mnt/usb"                # point de montage de la clé
FTP_DEBS="$USB_DIR/vsftpd.deb"    # ou "$USB_DIR/*.deb" si tu as plusieurs paquets

echo "[1/6] Configuration de l'adresse IP sur enp1s0f0…"

ip link set dev enp1s0f0 up
ip addr flush dev enp1s0f0
ip addr add 120.0.66.5/24 dev enp1s0f0

# Route par défaut vers le routeur de la DMZ (facultatif si tu n'en as pas besoin)
ip route add default via 120.0.66.1 || true

echo "[2/6] Vérification de la présence du paquet FTP sur la clé USB…"

if ! ls $FTP_DEBS >/dev/null 2>&1; then
    echo "ERREUR : aucun paquet FTP trouvé dans $FTP_DEBS"
    echo "Assure-toi d'avoir copié vsftpd.deb (et ses dépendances) dans $USB_DIR"
    exit 1
fi

echo "[3/6] Installation de vsftpd en local (sans Internet)…"

# Installation des paquets FTP depuis la clé
dpkg -i $FTP_DEBS || true

# Si certaines dépendances manquent et que tu les as aussi sur la clé :
# dpkg -i $USB_DIR/*.deb

# Vérifier si l’installation est OK
if ! dpkg -l | grep -q "^ii  vsftpd"; then
    echo "ERREUR : vsftpd ne semble pas installé correctement."
    echo "Vérifie que tu as bien toutes les dépendances sur la clé."
    exit 1
fi

echo "[4/6] Sauvegarde et configuration de /etc/vsftpd.conf…"

if [ -f /etc/vsftpd.conf ] && [ ! -f /etc/vsftpd.conf.bak ]; then
    cp /etc/vsftpd.conf /etc/vsftpd.conf.bak
fi

cat >/etc/vsftpd.conf <<EOF
listen=YES
listen_ipv6=NO

anonymous_enable=NO
local_enable=YES
write_enable=YES

chroot_local_user=YES
allow_writeable_chroot=YES

xferlog_enable=YES
ftpd_banner=Bienvenue sur le serveur FTP 120.0.66.5

# Mode passif (pratique derrière un pare-feu/routeur)
pasv_enable=YES
pasv_min_port=30000
pasv_max_port=30010
pasv_address=120.0.66.5
EOF

echo "[5/6] Création de l'utilisateur FTP local…"

# Crée l'utilisateur ftpuser s'il n'existe pas déjà
if ! id ftpuser >/dev/null 2>&1; then
    useradd -m ftpuser
    echo "ftpuser:ftp123" | chpasswd
fi

mkdir -p /home/ftpuser/ftp
chown -R ftpuser:ftpuser /home/ftpuser

echo "[6/6] Activation du service vsftpd…"

systemctl enable vsftpd || true
systemctl restart vsftpd

echo "-----------------------------------------"
echo " Serveur FTP installé et configuré."
echo " IP        : 120.0.66.5 (dev enp1s0f0)"
echo " Utilisateur : ftpuser"
echo " Mot de passe : ftp123"
echo " Port FTP  : 21 (passif 30000-30010)"
echo "-----------------------------------------"
