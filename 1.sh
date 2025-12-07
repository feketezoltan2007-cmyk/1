#!/usr/bin/env bash

set -e
export DEBIAN_FRONTEND=noninteractive

# Ellenőrzés, hogy root-e
if [[ $EUID -ne 0 ]]; then
  echo -e "\e[31mEzt a scriptet rootként kell futtatni!\e[0m"
  exit 1
fi

########################################
### TELEPÍTETTSÉG ELLENŐRZŐ FÜGGVÉNY ###
########################################
is_installed() {
  case "$1" in
    node-red)
      if command -v node-red >/dev/null 2>&1; then echo "telepítve"; else echo "nincs telepítve"; fi
      ;;
    lamp)
      if dpkg -l apache2 >/dev/null 2>&1 && dpkg -l mariadb-server >/dev/null 2>&1 && dpkg -l php >/dev/null 2>&1; then
        echo "telepítve"
      else
        echo "nincs telepítve"
      fi
      ;;
    mqtt)
      if dpkg -l mosquitto >/dev/null 2>&1; then echo "telepítve"; else echo "nincs telepítve"; fi
      ;;
    mc)
      if dpkg -l mc >/dev/null 2>&1; then echo "telepítve"; else echo "nincs telepítve"; fi
      ;;
  esac
}

########################################
###       FŐ MENÜ (Telepítés/Törlés) ###
########################################

clear
echo -e "\e[36mMit szeretnél?\e[0m"
echo -e "  \e[32m1\e[0m - Telepítés"
echo -e "  \e[31m2\e[0m - Eltávolítás"
read -rp $'\e[37mVálasztás (1/2): \e[0m' MODE </dev/tty || MODE=""

if [[ "$MODE" != "1" && "$MODE" != "2" ]]; then
  echo -e "\e[33mÉrvénytelen választás, kilépés.\e[0m"
  exit 1
fi

########################################
###              TELEPÍTÉS            ###
########################################
if [[ "$MODE" == "1" ]]; then

# telepítettségi státuszok
NODE_STATUS=$(is_installed node-red)
LAMP_STATUS=$(is_installed lamp)
MQTT_STATUS=$(is_installed mqtt)
MC_STATUS=$(is_installed mc)

INSTALL_NODE_RED=0
INSTALL_LAMP=0
INSTALL_MQTT=0
INSTALL_MC=0

echo -e "\e[36mMit szeretnél telepíteni? \e[0m"
echo -e "  \e[32m1\e[0m - MINDENT telepít"
echo -e "  \e[33m2\e[0m - Node-RED            – $NODE_STATUS"
echo -e "  \e[34m3\e[0m - Apache+MariaDB+PHP – $LAMP_STATUS"
echo -e "  \e[35m4\e[0m - MQTT (Mosquitto)   – $MQTT_STATUS"
echo -e "  \e[36m5\e[0m - mc                  – $MC_STATUS"

read -rp $'\e[37mVálasztás: \e[0m' CHOICES </dev/tty || CHOICES=""

# Ha az 1-es opció van kiválasztva, mindent telepít
if echo "$CHOICES" | grep -qw "1"; then
  INSTALL_NODE_RED=1
  INSTALL_LAMP=1
  INSTALL_MQTT=1
  INSTALL_MC=1
fi

# Egyéb opciók
for c in $CHOICES; do
  case "$c" in
    2) INSTALL_NODE_RED=1 ;;
    3) INSTALL_LAMP=1 ;;
    4) INSTALL_MQTT=1 ;;
    5) INSTALL_MC=1 ;;
  esac
done

# Ha nincs választás
if [[ $INSTALL_NODE_RED -eq 0 && $INSTALL_LAMP -eq 0 && $INSTALL_MQTT -eq 0 && $INSTALL_MC -eq 0 ]]; then
  echo -e "\e[33mNincs kiválasztva semmi, kilépés.\e[0m"
  exit 0
fi

########################################
### KONKRÉT TELEPÍTÉSI LÉPÉSEK
########################################

apt-get update -y && apt-get upgrade -y
apt-get install -y curl wget unzip ca-certificates gnupg lsb-release

# Node-RED telepítés
if [[ $INSTALL_NODE_RED -eq 1 ]]; then
  npm install -g --unsafe-perm node-red || true
fi

# LAMP telepítés
if [[ $INSTALL_LAMP -eq 1 ]]; then
  apt-get install -y apache2 mariadb-server php libapache2-mod-php php-mysql \
    php-mbstring php-zip php-gd php-json php-curl
fi

# MQTT telepítés
if [[ $INSTALL_MQTT -eq 1 ]]; then
  apt-get install -y mosquitto mosquitto-clients
fi

# mc telepítés
if [[ $INSTALL_MC -eq 1 ]]; then
  apt-get install -y mc
fi

echo -e "\e[32mTelepítés kész!\e[0m"
exit 0
fi  # TELEPÍTÉS vége



########################################
###              TÖRLÉS               ###
########################################
if [[ "$MODE" == "2" ]]; then

# telepítettségi státuszok
NODE_STATUS=$(is_installed node-red)
LAMP_STATUS=$(is_installed lamp)
MQTT_STATUS=$(is_installed mqtt)
MC_STATUS=$(is_installed mc)

REMOVE_NODE_RED=0
REMOVE_LAMP=0
REMOVE_MQTT=0
REMOVE_MC=0

echo -e "\e[31mMit szeretnél eltávolítani?\e[0m"
echo -e "  \e[33m1\e[0m - MINDENT"
echo -e "  \e[32m2\e[0m - Node-RED            – $NODE_STATUS"
echo -e "  \e[34m3\e[0m - Apache+MariaDB+PHP – $LAMP_STATUS"
echo -e "  \e[35m4\e[0m - MQTT (Mosquitto)   – $MQTT_STATUS"
echo -e "  \e[36m5\e[0m - mc                  – $MC_STATUS"

read -rp $'\e[37mVálasztás: \e[0m' DEL </dev/tty || DEL=""

# Ha 1 → mindent töröl
if echo "$DEL" | grep -qw "1"; then
  REMOVE_NODE_RED=1
  REMOVE_LAMP=1
  REMOVE_MQTT=1
  REMOVE_MC=1
fi

for d in $DEL; do
  case "$d" in
    2) REMOVE_NODE_RED=1 ;;
    3) REMOVE_LAMP=1 ;;
    4) REMOVE_MQTT=1 ;;
    5) REMOVE_MC=1 ;;
  esac
done

########################################
### KONKRÉT TÖRLÉSI LÉPÉSEK
########################################

# Node-RED törlése
if [[ $REMOVE_NODE_RED -eq 1 ]]; then
  npm remove -g node-red || true
fi

# LAMP törlése
if [[ $REMOVE_LAMP -eq 1 ]]; then
  apt-get purge -y apache2\* mariadb-server\* php\*
  rm -rf /usr/share/phpmyadmin
fi

# MQTT törlése
if [[ $REMOVE_MQTT -eq 1 ]]; then
  apt-get purge -y mosquitto\*
fi

# mc törlése
if [[ $REMOVE_MC -eq 1 ]]; then
  apt-get purge -y mc
fi

echo -e "\e[32mEltávolítás kész!\e[0m"
fi
