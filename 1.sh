#!/usr/bin/env bash

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

CHECK="${GREEN}[OK]${NC}"
ERR="${RED}[ERR]${NC}"
INFO="${BLUE}[INFO]${NC}"

set -e
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
  echo -e "${ERR} Rootként futtasd!"
  exit 1
fi

echo -e "${INFO} Rendszer frissítése..."
apt-get update -y && apt-get upgrade -y
apt-get install -y curl wget unzip ca-certificates gnupg lsb-release

# Node-RED telepítés
if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
  npm install -g --unsafe-perm node-red

  SERVICE="/etc/systemd/system/node-red.service"
  if [[ ! -f "$SERVICE" ]]; then
    cat >"$SERVICE" <<'UNIT'
[Unit]
Description=Node-RED
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/env node-red
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT
    systemctl daemon-reload
    systemctl enable --now node-red
  fi
fi

# LAMP telepítés
apt-get install -y apache2 mariadb-server php libapache2-mod-php php-mysql \
  php-mbstring php-zip php-gd php-json php-curl

systemctl enable apache2 mariadb
systemctl start apache2 mariadb

mysql -u root <<EOF
CREATE USER IF NOT EXISTS 'user'@'localhost' IDENTIFIED BY 'user123';
GRANT ALL PRIVILEGES ON *.* TO 'user'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# phpMyAdmin telepítés
cd /tmp
wget -q -O phpmyadmin.zip https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip
unzip -q phpmyadmin.zip
rm -rf /usr/share/phpmyadmin
mv phpMyAdmin-*-all-languages /usr/share/phpmyadmin
mkdir -p /usr/share/phpmyadmin/tmp
chmod 777 /usr/share/phpmyadmin/tmp

cat >/etc/apache2/conf-available/phpmyadmin.conf <<'APACHECONF'
Alias /phpmyadmin /usr/share/phpmyadmin
<Directory /usr/share/phpmyadmin>
    Options FollowSymLinks
    DirectoryIndex index.php
    Require all granted
</Directory>
APACHECONF

a2enconf phpmyadmin
systemctl reload apache2

# MQTT telepítés
apt-get install -y mosquitto mosquitto-clients
mkdir -p /etc/mosquitto/conf.d
cat >/etc/mosquitto/conf.d/local.conf <<'MQTT'
listener 1883
allow_anonymous true
MQTT

systemctl enable mosquitto
systemctl restart mosquitto

# mc telepítés
apt-get install -y mc

echo -e "${GREEN}Telepítés befejezve.${NC}"
exit 0
