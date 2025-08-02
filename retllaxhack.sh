#!/usr/bin/env bash

# RetllaxHack Modo Furtivo - Evasión de Firewalls/IDS
# Técnicas avanzadas de escaneo sigiloso

clear

## Configuración Stealth
VERSION="2.3-stealth"
LOG_FILE="ghost_scan.log"
TOR_PROXY="socks5://127.0.0.1:9050"  # Usar Tor como proxy

## Instalación de dependencias furtivas
function instalar_dependencias() {
  pkg update -y && pkg install -y nmap torsocks proxychains-ng dnsutils \
  && echo "[+] Herramientas stealth instaladas" | lolcat
}

## Técnicas de Evasión
function configurar_evasion() {
  # Randomizar MAC y delay
  MAC=$(printf "02:%02x:%02x:%02x:%02x:%02x" $((RANDOM%256)) $((RANDOM%256)) \
       $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))
  
  # Configuración de timing aleatorio
  SCAN_DELAY=$((RANDOM%7+1))  # Delay entre 1-7 segundos
  PARALLEL_SCANS=$((RANDOM%3+1))  # Escaneos paralelos: 1-3
  
  echo "[~] Configurando perfil furtivo..." | lolcat
  echo "- MAC Aleatoria: $MAC"
  echo "- Delay: $SCAN_DELAY seg"
  echo "- Escaneos paralelos: $PARALLEL_SCANS"
}

## Escaneo Furtivo Avanzado
function escaneo_furtivo() {
  read -p "Objetivo (IP/Dominio): " objetivo
  
  configurar_evasion
  
  echo "[+] Iniciando escaneo fantasma..." | lolcat
  nmap -sS -T2 -f --data-length 24 --randomize-hosts --spoof-mac $MAC \
       --scan-delay ${SCAN_DELAY}s --max-parallelism $PARALLEL_SCANS \
       --badsum -D RND:5 $objetivo -oN "ghost_scan_$objetivo.txt" | lolcat
}

## Fuerza Bruta Fantasma
function fuerza_bruta_furtiva() {
  read -p "Objetivo: " objetivo
  read -p "Servicio: " servicio
  
  # Usar proxychains sobre Tor
  echo "[+] Activando canal encubierto (Tor)..." | lolcat
  proxychains -q hydra -v -V -L usuarios.txt -P claves.txt \
              -e ns -t 2 -w $SCAN_DELAY -I $objetivo $servicio | lolcat
}

## Menú Stealth
function menu_principal() {
  while true; do
    clear
    figlet -f small "RetllaxHack" | lolcat
    echo "=== MODO EVASIÓN ===" | lolcat
    echo "1) Escaneo Fantasma (Stealth)"
    echo "2) Fuerza Bruta Encubierta"
    echo "3) Auto-Limpieza de Logs"
    echo "4) Salir"
    echo ""
    read -p "Opción: " opcion

    case $opcion in
      1) escaneo_furtivo ;;
      2) fuerza_bruta_furtiva ;;
      3) rm -f ghost_scan* 2>/dev/null ;;
      4) exit 0 ;;
      *) echo "Opción inválida"; sleep 1 ;;
    esac
    read -p "Enter para continuar..."
  done
}

## Inicio
instalar_dependencias
menu_principal
