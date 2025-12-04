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

echo -e "${YELLOW}Mit szeretnél telepíteni?${NC}"
echo -e "  1 - Node-RED"
echo -e "  2 - Apache2 + MariaDB + PHP + phpMyAdmin"
echo -e "  3 - MQTT (Mosquitto)"
echo -e "  4 - mc (Midnight Commander)"
echo -e "  5 - MINDENT telepít"
echo
read -rp "Választás (pl. 1 vagy 1 2 3): " CHOICES

NODE_RED=0
LAMP=0
MQTT=0
MC=0

if echo "$CHOICES" | grep -qw "5"; then
  NODE_RED=1
  LAMP=1
  MQTT=1
  MC=1
fi

for c in $CHOICES; do
  case "$c" in
    1) NODE_RED=1 ;;
    2) LAMP=1 ;;
    3) MQTT=1 ;;
    4) MC=1 ;;
    5) ;;
    *) echo -e "${YELLOW}[!] Ismeretlen opció: $c${NC}" ;;
  esac
done

if [[ $NODE_RED -eq 0 && $LAMP -eq 0 && $MQTT -eq 0 && $MC -eq 0 ]]; then
  echo -e "${ERR} Nem választottál semmit."
  exit 0
fi

echo -e "${GREEN}Telepítés befejezve.${NC}"
exit 0
