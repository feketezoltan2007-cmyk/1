#!/usr/bin/env bash

set -e
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
  echo "Ezt a scriptet rootként kell futtatni!"
  exit 1
fi

INSTALL_NODE_RED=0
INSTALL_LAMP=0
INSTALL_MQTT=0
INSTALL_MC=0

echo "Mit szeretnél telepíteni?"
echo "  1 - MINDENT telepít (Node-RED, LAMP, MQTT, mc)"
echo "  2 - Node-RED"
echo "  3 - Apache2 + MariaDB + PHP + phpMyAdmin"
echo "  4 - MQTT szerver (Mosquitto)"
echo "  5 - mc"

read -rp "Választás (pl. 1 vagy 2 4 5): " CHOICES </dev/tty || CHOICES=""

for c in $CHOICES; do
  case "$c" in
    1)
      INSTALL_NODE_RED=1
      INSTALL_LAMP=1
      INSTALL_MQTT=1
      INSTALL_MC=1
      ;;
    2) INSTALL_NODE_RED=1 ;;
    3) INSTALL_LAMP=1 ;;
    4) INSTALL_MQTT=1 ;;
    5) INSTALL_MC=1 ;;
    *) echo "Ismeretlen opció: $c, kihagyva." ;;
  esac
done

if [[ $INSTALL_NODE_RED -eq 0 && $INSTALL_LAMP -eq 0 && $INSTALL_MQTT -eq 0 && $INSTALL_MC -eq 0 ]]; then
  echo "Nem választottál semmit, kilépek."
  exit 0
fi

# Frissítés és alap csomagok
apt-get update -y && apt-get upgrade -y
apt-get install -y curl wget unzip ca-certificates gnupg lsb-release

# Node-RED telepítés
if [[ $INSTALL_NODE_RED -eq 1 ]]; then
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
Environment="NODE_OPTIONS=--max_old_space_size=256"

[Install]
WantedBy=multi-user.target
UNIT
      systemctl daemon-reload
    fi
  fi
fi

# LAMP telepítés
if [[ $INSTALL_LAMP -eq 1 ]]; then
  apt-get install -y apache2 mariadb-server php libapache2-mod-php php-mysql \
    php-mbstring php-zip php-gd php-json php-curl

  systemctl enable apache2 mariadb
  systemctl start apache2 mariadb

  mysql -u root <<EOF
CREATE USER IF NOT EXISTS 'user'@'localhost' IDENTIFIED BY 'user123';
GRANT ALL PRIVILEGES ON *.* TO 'user'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

  cd /tmp
  wget -q -O phpmyadmin.zip https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip
  unzip -q phpmyadmin.zip
  rm phpmyadmin.zip
  rm -rf /usr/share/phpmyadmin
  mv phpMyAdmin-*-all-languages /usr/share/phpmyadmin
  mkdir -p /usr/share/phpmyadmin/tmp
  chown -R www-data:www-data /usr/share/phpmyadmin
  chmod 777 /usr/share/phpmyadmin/tmp

  cat >/etc/apache2/conf-available/phpmyadmin.conf <<'APACHECONF'
Alias /phpmyadmin /usr/share/phpmyadmin

<Directory /usr/share/phpmyadmin>
    Options FollowSymLinks
    DirectoryIndex index.php
    AllowOverride All
    Require all granted
</Directory>
APACHECONF

  a2enconf phpmyadmin

  cat >/usr/share/phpmyadmin/config.inc.php <<'PHPCONF'
<?php
$cfg['blowfish_secret'] = 'RandomStrongSecretKey123456!';
$i = 0;
$i++;
$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['host'] = 'localhost';
$cfg['Servers'][$i]['AllowNoPassword'] = false;
PHPCONF

  systemctl reload apache2
fi

# MQTT telepítés
if [[ $INSTALL_MQTT -eq 1 ]]; then
  apt-get install -y mosquitto mosquitto-clients
  mkdir -p /etc/mosquitto/conf.d
  cat >/etc/mosquitto/conf.d/local.conf <<'MQTTCONF'
listener 1883
allow_anonymous true
MQTTCONF
  systemctl enable mosquitto
  systemctl restart mosquitto
fi

# mc telepítés
if [[ $INSTALL_MC -eq 1 ]]; then
  apt-get install -y mc
fi
