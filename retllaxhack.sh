#!/bin/bash

# RetllaxHack - Herramienta básica de auditoría para Termux

clear
echo "======================================="
echo "           RetllaxHack                 "
echo "     Herramienta de auditoría básica   "
echo "======================================="
echo

function check_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[ERROR] '$1' no está instalado. Por favor instala antes de continuar."
    exit 1
  }
}

check_command nmap
check_command hydra

menu() {
  echo "Menú Principal:"
  echo "1) Escaneo automático de puertos"
  echo "2) Ataque de fuerza bruta con Hydra (solo laboratorio)"
  echo "3) Salir"
  echo
  read -p "Elige una opción: " opcion

  case $opcion in
    1) scan_ports ;;
    2) hydra_attack ;;
    3) echo "Adiós."; exit 0 ;;
    *) echo "Opción no válida"; menu ;;
  esac
}

scan_ports() {
  read -p "Introduce la IP o dominio a escanear: " objetivo
  echo
  echo "[*] Escaneo rápido (top 1000 puertos más comunes)..."
  echo "-----------------------------------"
  nmap -sS --top-ports 1000 -T4 --open "$objetivo"

  abiertos=$(nmap -sS --top-ports 1000 -T4 --open "$objetivo" | grep -c "open")

  if [ "$abiertos" -gt 0 ]; then
    echo
    echo "[+] Se detectaron $abiertos puertos abiertos."
    echo "[*] Lanzando escaneo completo de todos los puertos abiertos..."
    echo "-----------------------------------"
    nmap -sS -p- -T4 --open "$objetivo"
    echo
    echo "[OK] Escaneo completo finalizado."
  else
    echo
    echo "[!] No se detectaron puertos abiertos en el escaneo rápido."
    echo "[!] No se realiza escaneo completo."
  fi
  echo
  menu
}

hydra_attack() {
  echo
  echo "ATENCIÓN: Use esta opción solo en máquinas que tiene permiso para auditar."
  echo
  read -p "Introduce la IP o dominio objetivo: " objetivo
  read -p "Introduce el servicio (ej: ssh, ftp, http-get): " servicio
  read -p "Introduce la ruta al archivo de usuario (wordlist de usuarios): " usuarios
  read -p "Introduce la ruta al archivo de contraseñas (wordlist de passwords): " passwords

  if [ ! -f "$usuarios" ]; then
    echo "[!] Archivo de usuarios no encontrado."
    menu
  fi

  if [ ! -f "$passwords" ]; then
    echo "[!] Archivo de contraseñas no encontrado."
    menu
  fi

  echo
  echo "[*] Ejecutando Hydra..."
  hydra -L "$usuarios" -P "$passwords" -f -o hydra_result.txt "$objetivo" "$servicio"
  echo
  echo "[OK] Hydra finalizó. Resultados guardados en hydra_result.txt"
  echo "Puede revisar el archivo con 'cat hydra_result.txt'."
  echo
  menu
}

menu
