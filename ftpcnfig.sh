#!/bin/bash
# ======================================
# Configuration vsftpd - FTP ANONYMOUS
# Projet scolaire
# ======================================

set -e

echo "[+] Configuration de /etc/vsftpd.conf ..."

sudo tee /etc/vsftpd.conf > /dev/null <<'EOF'
# ================================
# vsftpd - FTP ANONYMOUS (PROJET)
# ================================

listen=YES
listen_ipv6=NO

anonymous_enable=YES
local_enable=NO

anon_root=/srv/ftp

write_enable=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES

# Sécurité chroot (racine NON writable)
chroot_local_user=NO
EOF

echo "[+] Configuration terminée."
