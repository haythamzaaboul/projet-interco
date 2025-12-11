# Le fichier index.html doit etre dans le meme dossier que le script

ip a add 120.0.66.2/24 dev enp1s0f0
ip link set dev enp1s0f0 up
service apache2 start

DIR="$(dirname "$0")"
SOURCE="$DIR/index.html"
DEST="~/../var/www/html"

cp "$SOURCE" "$DEST"