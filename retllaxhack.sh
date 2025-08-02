#!/usr/bin/env bash

# RetllaxHack Pro RGB Edition (v4.0)
# Efectos de color dinámicos - 100% funcional sin root

# ===== CONFIGURACIÓN RGB =====
function rgb_effect {
  case $(($RANDOM % 6)) in
    0) echo -e "\033[1;31m$1\033[0m";;  # Rojo
    1) echo -e "\033[1;32m$1\033[0m";;  # Verde
    2) echo -e "\033[1;33m$1\033[0m";;  # Amarillo
    3) echo -e "\033[1;34m$1\033[0m";;  # Azul
    4) echo -e "\033[1;35m$1\033[0m";;  # Magenta
    5) echo -e "\033[1;36m$1\033[0m";;  # Cyan
  esac
}

# ===== BANNER ANIMADO =====
function show_banner() {
  clear
  rgb_effect "  ____      _   _   _       _     _    _      "
  rgb_effect " |  _ \ ___| |_| | | | __ _| |__ | | _| |__  "
  rgb_effect " | |_) / _ \ __| |_| |/ _\` | '_ \| |/ / '_ \ "
  rgb_effect " |  _ <  __/ |_|  _  | (_| | | | |   <| | | |"
  rgb_effect " |_| \_\___|\__|_| |_|\__,_|_| |_|_|\_\_| |_|"
  echo
  rgb_effect "=== HERRAMIENTA PROFESIONAL DE AUDITORÍA ==="
  rgb_effect "=========== TERMUX EDITION v4.0 ============"
  echo
}

# ===== ESCANEO DINÁMICO RGB =====
function dynamic_scan() {
  show_banner
  read -p "$(rgb_effect "[?] IP/Dominio: ")" target
  
  # Configuración inteligente
  delay=$((RANDOM%4+2))
  ports="21,22,80,443,8080,8443,3306,3389"
  
  rgb_effect "[~] Configurando escaneo RGB..."
  echo -e "$(rgb_effect "• Técnica:") $(rgb_effect "Escaneo CONNECT")"
  echo -e "$(rgb_effect "• Retardo:") $(rgb_effect "${delay}s")"
  echo -e "$(rgb_effect "• Puertos:") $(rgb_effect "$ports")"
  
  rgb_effect "\n[+] Iniciando escaneo..."
  nmap -Pn -T4 --max-retries 1 --scan-delay ${delay}s -p $ports $target | \
    while read line; do
      if [[ $line == *"open"* ]]; then
        rgb_effect "[+] $line"
      elif [[ $line == *"filtered"* ]]; then
        rgb_effect "[?] $line"
      else
        echo "$line"
      fi
    done | tee scan_results.log
    
  rgb_effect "\n[✔] Escaneo completado!"
  rgb_effect "Resultados guardados en scan_results.log"
}

# ===== MENÚ RGB =====
function rgb_menu() {
  while true; do
    show_banner
    rgb_effect "1) Escaneo RGB Dinámico"
    rgb_effect "2) Ver Resultados"
    rgb_effect "3) Actualizar Herramienta"
    rgb_effect "4) Salir"
    echo
    read -p "$(rgb_effect "[?] Seleccione una opción: ")" opt

    case $opt in
      1) dynamic_scan ;;
      2) [ -f "scan_results.log" ] && cat scan_results.log || rgb_effect "[!] No hay resultados";;
      3) curl -sL https://raw.githubusercontent.com/tu_repo/RetllaxHack/main/retllaxhack.sh > update.sh && 
         chmod +x update.sh && 
         mv update.sh retllaxhack.sh && 
         rgb_effect "[✔] Actualización completada!";;
      4) exit 0 ;;
      *) rgb_effect "[!] Opción inválida"; sleep 1 ;;
    esac
    read -p "$(rgb_effect "\nPresione Enter para continuar...")"
  done
}

# ===== INICIO =====
show_banner
rgb_effect "[~] Inicializando efectos RGB..."
sleep 2
rgb_menu
