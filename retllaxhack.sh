#!/usr/bin/env bash

# RetllaxHack - Modo Evasión Sin Root (v2.7)
# Versión definitiva para Termux

# Configuración
VERSION="2.7"
LOG_FILE="scan.log"

# Colores
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m'

# Banner
function show_banner() {
  clear
  echo -e "${PURPLE}"
  echo " ___     _   _ _          _  _         _"
  echo "| _ \___| |_| | |__ ___ _| || |__ _ __| |__"
  echo "|   / -_)  _| | / _\` \\ \\ / __ / _\` / _| / /"
  echo "|_|_\___|\\__|_|_\\__,_/_\\_\\_||_\\__,_\\__|_\\_\\"
  echo -e "${NC}"
  echo -e "${BLUE}=== MODO EVASIÓN SIN ROOT ==="
  echo -e "=== Versión ${VERSION} ===${NC}"
}

# Escaneo seguro sin root
function escaneo_seguro() {
  show_banner
  read -p "${CYAN}[?] IP/Dominio: ${NC}" target
  
  # Configuración adaptativa
  delay=$((RANDOM%3+2))
  ports="21,22,80,443,8080,8443" # Puertos comunes
  
  echo -e "${YELLOW}[~] Técnicas activadas:${NC}"
  echo -e "- ${GREEN}Escaneo CONNECT (no SYN)${NC}"
  echo -e "- ${GREEN}Retardo: ${delay}s${NC}"
  echo -e "- ${GREEN}Puertos estratégicos${NC}"
  
  echo -e "\n${BLUE}[+] Escaneando...${NC}"
  nmap -Pn -T4 --max-retries 1 --scan-delay ${delay}s -p $ports $target \
    | tee -a $LOG_FILE \
    | grep --color -E "open|filtered|closed"
  
  echo -e "\n${GREEN}[✔] Resultados en ${RED}$LOG_FILE${NC}"
}

# Menú principal
function menu() {
  while true; do
    show_banner
    echo -e "${GREEN}1) Escaneo Seguro"
    echo -e "${GREEN}2) Fuerza Bruta (Tor)"
    echo -e "${GREEN}3) Ver Logs"
    echo -e "${RED}4) Salir${NC}"
    echo
    read -p "${CYAN}[?] Opción: ${NC}" opt

    case $opt in
      1) escaneo_seguro ;;
      2) echo -e "${YELLOW}Opción deshabilitada en esta versión${NC}" ;;
      3) [ -f "$LOG_FILE" ] && cat $LOG_FILE || echo -e "${RED}No hay logs${NC}" ;;
      4) exit 0 ;;
      *) echo -e "${RED}[!] Opción inválida${NC}"; sleep 1 ;;
    esac
    read -p "${CYAN}[?] Enter para continuar...${NC}"
  done
}

# Inicio
menu
