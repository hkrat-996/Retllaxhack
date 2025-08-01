#!/bin/bash

# RetllaxHack - Herramienta mejorada con colores y banner

clear

# Mostrar título grande y colorido
figlet -c "RetllaxHack" | lolcat
echo "============================================" | lolcat
echo "   Herramienta de auditoría básica (v1.1)   " | lolcat
echo "    By Axel (Rotllax) - Termux Edition      " | lolcat
echo "============================================" | lolcat
echo

# Verificar dependencias
function check_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[ERROR] '$1' no está instalado. Por favor instala antes de continuar." | lolcat
    exit 1
  }
}

check_command nmap
check_command hydra
check_command figlet
check_command lolcat

# Menú principal
menu() {
  echo "Menú Principal:" | lolcat
  echo "1) Escaneo automático de puertos" | lolcat
  echo "2) Ataque de fuerza bruta con Hydra (uso en laboratorio)" | lolcat
  echo "3) Escaneo de vulnerabilidades (Nmap NSE)" | lolcat
  echo "4) Salir" | lolcat
  echo
  read -p "Elige una opción: " opcion

  case $opcion in
    1) scan_ports ;;
    2) hydra_attack ;;
    3) vuln_scan ;;
    4) echo "Adiós." | lolcat; exit 0 ;;
    *) echo "Opción no válida" | lolcat; menu ;;
  esac
}

# Escaneo de puertos
scan_ports() {
  read -p "Introduce la IP o dominio a escanear: " objetivo
  echo
  echo "[*] Escaneo rápido (top 1000 puertos más comunes)..." | lolcat
  echo "-----------------------------------" | lolcat
  nmap -sS --top-ports 1000 -T4 --open "$objetivo" | lolcat

  abiertos=$(nmap -sS --top-ports 1000 -T4 --open "$objetivo" | grep -c "open")

  if [ "$abiertos" -gt 0 ]; then
    echo
    echo "[+] Se detectaron $abiertos puertos abiertos." | lolcat
    echo "[*] Lanzando escaneo completo de todos los puertos..." | lolcat
    echo "-----------------------------------" | lolcat
    nmap -sS -p- -T4 --open "$objetivo" | lolcat
    echo
    echo "[OK] Escaneo completo finalizado." | lolcat
  else
    echo
    echo "[!] No se detectaron puertos abiertos en el escaneo rápido." | lolcat
    echo "[!] No se realiza escaneo completo." | lolcat
  fi
  echo
  menu
}

# Ataque con hydra
hydra_attack() {
  echo
  echo "ATENCIÓN: Usa esta opción solo en entornos controlados y con permiso." | lolcat
  echo
  read -p "Introduce la IP o dominio objetivo: " objetivo
  read -p "Introduce el servicio (ej: ssh, ftp, http-get): " servicio
  read -p "Ruta al archivo de usuarios (wordlist): " usuarios
  read -p "Ruta al archivo de contraseñas (wordlist): " passwords

  if [ ! -f "$usuarios" ]; then
    echo "[!] Archivo de usuarios no encontrado." | lolcat
    menu
  fi

  if [ ! -f "$passwords" ]; then
    echo "[!] Archivo de contraseñas no encontrado." | lolcat
    menu
  fi

  echo
  echo "[*] Ejecutando Hydra..." | lolcat
  hydra -L "$usuarios" -P "$passwords" -f -o hydra_result.txt "$objetivo" "$servicio" | lolcat
  echo
  echo "[OK] Hydra finalizó. Resultados guardados en hydra_result.txt" | lolcat
  echo "Puedes verlos con 'cat hydra_result.txt'." | lolcat
  echo
  menu
}

# Escaneo de vulnerabilidades
vuln_scan() {
  read -p "Introduce la IP o dominio a escanear vulnerabilidades: " objetivo
  echo
  echo "[*] Escaneando vulnerabilidades conocidas con Nmap NSE..." | lolcat
  echo "-----------------------------------" | lolcat
  nmap -sV --script vuln "$objetivo" | lolcat
  echo
  echo "[OK] Escaneo de vulnerabilidades completado." | lolcat
  echo
  menu
}

menu
