#!/bin/bash

# RetllaxHack - Herramienta avanzada by Axel (Rotllax)

clear
figlet -c "RetllaxHack" | lolcat
echo "============================================" | lolcat
echo "   Herramienta de auditoría avanzada (v1.3) " | lolcat
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
  echo "4) Escaneo global de hosts (con lista de dominios o IPs)" | lolcat
  echo "5) Salir" | lolcat
  echo
  read -p "Elige una opción: " opcion

  case $opcion in
    1) scan_ports ;;
    2) hydra_attack ;;
    3) vuln_scan ;;
    4) global_scan ;;
    5) echo "Adiós." | lolcat; exit 0 ;;
    *) echo "Opción no válida" | lolcat; menu ;;
  esac
}

# Escaneo automático de puertos
scan_ports() {
  read -p "Introduce la IP o dominio a escanear: " objetivo
  if [[ -z "$objetivo" ]]; then
    echo "[!] No ingresaste ningún objetivo." | lolcat
    menu
  fi
  echo
  echo "[*] Escaneo rápido (top 1000 puertos)..." | lolcat
  echo "-----------------------------------" | lolcat
  nmap -Pn -sV --top-ports 1000 "$objetivo" | lolcat

  echo
  echo "[OK] Escaneo finalizado." | lolcat
  echo
  menu
}

# Fuerza bruta con Hydra
hydra_attack() {
  echo
  echo "ATENCIÓN: Usa esto solo con permiso o en laboratorio." | lolcat
  echo
  read -p "IP o dominio objetivo: " objetivo
  read -p "Servicio (ej: ssh, ftp, http-get): " servicio
  read -p "Archivo de usuarios (wordlist): " usuarios
  read -p "Archivo de contraseñas (wordlist): " passwords

  if [ ! -f "$usuarios" ]; then
    echo "[!] Wordlist de usuarios no encontrada." | lolcat
    menu
  fi

  if [ ! -f "$passwords" ]; then
    echo "[!] Wordlist de contraseñas no encontrada." | lolcat
    menu
  fi

  echo
  echo "[*] Ejecutando Hydra..." | lolcat
  hydra -L "$usuarios" -P "$passwords" -f -o hydra_result.txt "$objetivo" "$servicio" | lolcat
  echo
  echo "[OK] Hydra finalizó. Resultados en hydra_result.txt" | lolcat
  echo
  menu
}

# Escaneo de vulnerabilidades con Nmap NSE
vuln_scan() {
  read -p "IP o dominio para buscar vulnerabilidades: " objetivo
  if [[ -z "$objetivo" ]]; then
    echo "[!] No ingresaste ningún objetivo." | lolcat
    menu
  fi
  echo
  echo "[*] Escaneando vulnerabilidades conocidas..." | lolcat
  echo "-----------------------------------" | lolcat
  nmap -Pn -sV --script vuln "$objetivo" | lolcat
  echo
  echo "[OK] Escaneo completado." | lolcat
  echo
  menu
}

# Escaneo global (lista de IPs o dominios)
global_scan() {
  read -p "Ruta del archivo con IPs o dominios (uno por línea): " lista
  if [ ! -f "$lista" ]; then
    echo "[!] Archivo no encontrado." | lolcat
    menu
  fi

  read -p "¿Guardar resultados? (s/n): " guardar
  if [[ "$guardar" =~ ^[sS]$ ]]; then
    read -p "Nombre del archivo para guardar (ej: global_scan.txt): " archivo
    if [[ -z "$archivo" ]]; then
      echo "[!] Nombre inválido, no se guardará." | lolcat
      archivo=""
    fi
  else
    archivo=""
  fi

  echo
  echo "[*] Iniciando escaneo global..." | lolcat

  while read objetivo; do
    if [[ -z "$objetivo" ]]; then continue; fi
    echo "-----------------------------------" | lolcat
    echo "[*] Escaneando $objetivo..." | lolcat
    if [[ -z "$archivo" ]]; then
      nmap -Pn -sV --top-ports 1000 "$objetivo" | lolcat
      nmap -Pn -sV --script vuln "$objetivo" | lolcat
    else
      nmap -Pn -sV --top-ports 1000 "$objetivo" | tee -a "$archivo" | lolcat
      nmap -Pn -sV --script vuln "$objetivo" | tee -a "$archivo" | lolcat
    fi
  done < "$lista"

  echo
  echo "[OK] Escaneo global finalizado." | lolcat
  if [[ -n "$archivo" ]]; then
    echo "Resultados guardados en $archivo" | lolcat
  fi
  echo
  menu
}

menu
