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
      command -v node-red >/dev/null 2>&1 && echo "telepítve" || echo "nincs telepítve"
      ;;
    lamp)
      if dpkg -s apache2 mariadb-server php 2>/dev/null | grep -q "install ok installed"; then
        echo "telepítve"
      else
        echo "nincs telepítve"
      fi
      ;;
    mqtt)
      dpkg -s mosquitto 2>/dev/null | grep -q "install ok installed" && echo "telepítve" || echo "nincs telepítve"
      ;;
    mc)
      dpkg -s mc 2>/dev/null | grep -q "install ok installed" && echo "telepítve" || echo "nincs telepítve"
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

[[ "$MODE" != "1" && "$MODE" != "2" ]] && exit 1

########################################
###              TELEPÍTÉS            ###
########################################
if [[ "$MODE" == "1" ]]; then

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
echo -e "  \e[94m3\e[0m - Apache+MariaDB+PHP – $LAMP_STATUS"
echo -e "  \e[35m4\e[0m - MQTT (Mosquitto)   – $MQTT_STATUS"
echo -e "  \e[36m5\e[0m - mc                  – $MC_STATUS"

read -rp $'\e[37mVálasztás: \e[0m' CHOICES </dev/tty || CHOICES=""

if echo "$CHOICES" | grep -qw "1"; then
  INSTALL_NODE_RED=1
  INSTALL_LAMP=1
  INSTALL_MQTT=1
  INSTALL_MC=1
fi

for c in $CHOICES; do
  case "$c" in
    2) INSTALL_NODE_RED=1 ;;
    3) INSTALL_LAMP=1 ;;
    4) INSTALL_MQTT=1 ;;
    5) INSTALL_MC=1 ;;
  esac
done

apt-get update -y && apt-get upgrade -y
apt-get install -y curl wget unzip ca-certificates gnupg lsb-release

[[ $INSTALL_NODE_RED -eq 1 ]] && npm install -g --unsafe-perm node-red || true
[[ $INSTALL_LAMP -eq 1 ]] && apt-get install -y apache2 mariadb-server php libapache2-mod-php php-mysql php-mbstring php-zip php-gd php-json php-curl
[[ $INSTALL_MQTT -eq 1 ]] && apt-get install -y mosquitto mosquitto-clients
[[ $INSTALL_MC -eq 1 ]] && apt-get install -y mc

echo -e "\e[32mTelepítés kész!\e[0m"
exit 0
fi

########################################
###              TÖRLÉS               ###
########################################
if [[ "$MODE" == "2" ]]; then

NODE_STATUS=$(is_installed node-red)
LAMP_STATUS=$(is_installed lamp)
MQTT_STATUS=$(is_installed mqtt)
MC_STATUS=$(is_installed mc)

echo -e "\e[31mMit szeretnél eltávolítani?\e[0m"
echo -e "  \e[33m1\e[0m - MINDENT"
echo -e "  \e[32m2\e[0m - Node-RED            – $NODE_STATUS"
echo -e "  \e[94m3\e[0m - Apache+MariaDB+PHP – $LAMP_STATUS"
echo -e "  \e[35m4\e[0m - MQTT (Mosquitto)   – $MQTT_STATUS"
echo -e "  \e[36m5\e[0m - mc                  – $MC_STATUS"

read -rp $'\e[37mVálasztás: \e[0m' DEL </dev/tty || DEL=""

[[ "$DEL" =~ 1 ]] && REMOVE_NODE_RED=1 REMOVE_LAMP=1 REMOVE_MQTT=1 REMOVE_MC=1

[[ "$DEL" =~ 2 ]] && npm remove -g node-red || true
[[ "$DEL" =~ 3 ]] && apt-get purge -y apache2\* mariadb-server\* php\*
[[ "$DEL" =~ 4 ]] && apt-get purge -y mosquitto\*
[[ "$DEL" =~ 5 ]] && apt-get purge -y mc

echo -e "\e[32mEltávolítás kész!\e[0m"
fi
