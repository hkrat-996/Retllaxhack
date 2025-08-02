#!/usr/bin/env bash

# RetllaxHack - Herramienta de auditoría mejorada (v1.3)

clear

# Mostrar título grande y colorido
figlet -c "RetllaxHack" | lolcat
echo "============================================" | lolcat
echo "   Herramienta de auditoría básica (v1.3)   " | lolcat
echo "        Termux Edition - Open Source        " | lolcat
echo "============================================" | lolcat
echo

# Auto-instalador de dependencias
function check_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[!] '$1' no está instalado." | lolcat
    read -p "¿Quieres instalarlo ahora? (s/n): " install
    if [[ "$install" =~ ^[sS]$ ]]; then
      pkg install -y "$1"
    else
      echo "[ERROR] Necesitas '$1' para continuar." | lolcat
      exit 1
    fi
  }
}

check_command nmap
check_command hydra
check_command figlet
check_command lolcat
check_command git

# Función para validar IP o dominio (básica)
function validar_objetivo() {
  local obj="$1"
  if [[ -z "$obj" ]]; then
    echo "[ERROR] No se ingresó ningún objetivo." | lolcat
    return 1
  fi
  if [[ "$obj" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    IFS='.' read -r -a octetos <<< "$obj"
    for octeto in "${octetos[@]}"; do
      if ((octeto > 255)); then
        echo "[ERROR] IP inválida: octeto $octeto mayor a 255." | lolcat
        return 1
      fi
    done
    return 0
  fi
  if [[ "$obj" =~ ^[a-zA-Z0-9.-]+$ ]]; then
    return 0
  fi
  echo "[ERROR] Objetivo inválido. Debe ser IP o dominio válido." | lolcat
  return 1
}

# Menú principal
menu() {
  echo "Menú Principal:" | lolcat
  echo "1) Escaneo automático de puertos" | lolcat
  echo "2) Ataque de fuerza bruta con Hydra (uso en laboratorio)" | lolcat
  echo "3) Escaneo de vulnerabilidades (Nmap NSE)" | lolcat
  echo "4) Escaneo global de hosts (varios objetivos)" | lolcat
  echo "5) Actualizar herramienta desde GitHub" | lolcat
  echo "6) Salir" | lolcat
  echo
  read -p "Elige una opción: " opcion

  case $opcion in
    1) scan_ports ;;
    2) hydra_attack ;;
    3) vuln_scan ;;
    4) global_scan ;;
    5) update_tool ;;
    6) echo "Adiós." | lolcat; exit 0 ;;
    *) echo "Opción no válida" | lolcat; menu ;;
  esac
}

# Escaneo de puertos (solo top 1000)
scan_ports() {
  read -p "Introduce la IP o dominio a escanear: " objetivo
  if ! validar_objetivo "$objetivo"; then
    menu
  fi

  echo
  echo "[*] Escaneo rápido (top 1000 puertos más comunes)..." | lolcat
  echo "-----------------------------------" | lolcat

  resultado=$(nmap -T3 --top-ports 1000 --open "$objetivo" 2>&1)
  exit_code=$?

  if [ $exit_code -ne 0 ]; then
    echo "[ERROR] Nmap falló: $resultado" | lolcat
    echo
    menu
  fi

  echo "$resultado" | lolcat

  abiertos=$(echo "$resultado" | grep -E "^[0-9]+/tcp\s+open" | wc -l)

  if [ "$abiertos" -gt 0 ]; then
    echo
    echo "[+] Se detectaron $abiertos puertos abiertos en $objetivo." | lolcat
  else
    echo
    echo "[!] No se detectaron puertos abiertos en el escaneo rápido." | lolcat
  fi
  echo
  menu
}

# Ataque con Hydra
hydra_attack() {
  echo
  echo "ATENCIÓN: Usa esta opción solo en entornos controlados y con permiso." | lolcat
  echo
  read -p "Introduce la IP o dominio objetivo: " objetivo
  if ! validar_objetivo "$objetivo"; then
    menu
  fi
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
  echo
  menu
}

# Escaneo de vulnerabilidades
vuln_scan() {
  read -p "Introduce la IP o dominio a escanear vulnerabilidades: " objetivo
  if ! validar_objetivo "$objetivo"; then
    menu
  fi
  echo
  echo "[*] Escaneando vulnerabilidades conocidas con Nmap NSE..." | lolcat
  echo "-----------------------------------" | lolcat
  nmap -sV --script vuln "$objetivo" | lolcat
  echo
  echo "[OK] Escaneo completado." | lolcat
  echo
  menu
}

# Escaneo global (varios objetivos)
global_scan() {
  echo
  echo "[*] Escaneo global (puedes ingresar varias IPs o dominios separados por espacio):" | lolcat
  read -p "Introduce los objetivos: " objetivos

  if [[ -z "$objetivos" ]]; then
    echo "[ERROR] No se ingresaron objetivos." | lolcat
    menu
  fi

  total=0
  encontrados=0

  for objetivo in $objetivos; do
    if validar_objetivo "$objetivo"; then
      total=$((total+1))
      echo
      echo "[*] Escaneando $objetivo..." | lolcat
      resultado=$(nmap -T3 --top-ports 1000 --open "$objetivo" 2>&1)
      exit_code=$?

      if [ $exit_code -ne 0 ]; then
        echo "[ERROR] Nmap falló en $objetivo: $resultado" | lolcat
        continue
      fi

      echo "$resultado" | lolcat
      abiertos=$(echo "$resultado" | grep -E "^[0-9]+/tcp\s+open" | wc -l)
      if [ "$abiertos" -gt 0 ]; then
        encontrados=$((encontrados+1))
        echo "[+] Se detectaron $abiertos puertos abiertos en $objetivo." | lolcat
      else
        echo "[-] No se detectaron puertos abiertos en $objetivo." | lolcat
      fi
    fi
  done

  echo
  echo "[Resumen global]" | lolcat
  echo "Total hosts escaneados: $total" | lolcat
  echo "Hosts con puertos abiertos: $encontrados" | lolcat
  echo
  menu
}

# Actualizar herramienta desde GitHub
update_tool() {
  echo
  echo "[*] Guardando cambios locales antes de actualizar..." | lolcat
  git add . && git commit -m "Cambios locales automáticos" >/dev/null 2>&1
  echo "[*] Actualizando herramienta desde GitHub..." | lolcat
  if git pull; then
    echo "[OK] Herramienta actualizada correctamente." | lolcat
  else
    echo "[ERROR] No se pudo actualizar." | lolcat
  fi
  echo
  menu
}

menu
