#!/usr/bin/env bash

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
  rgb "               SHADOW EDITION + METASPLOIT v9.0.4"
  echo
  rgb "=== ESCANEO POR ETAPAS | DETECCIÓN DE WAF | NO ROOT ==="
  echo
}

# ===== DETECCIÓN DE PROTECCIONES =====
function detect_protections {
  target=$1
  rgb "[~] Analizando protecciones en $target..."
  
  # Detección de WAF/Proxy
  if curl -sI "http://$target" | grep -iE "cloudflare|akamai|incapsula|barracuda"; then
    rgb "[⚠️] Detectado WAF: $(curl -sI "http://$target" | grep -iE "server:|x-protected-by")"
    return 1
  fi

  # Prueba de tasa de bloqueo
  if nmap -Pn -p 80 --host-timeout 1m $target | grep -q "blocked"; then
    rgb "[⚠️] Firewall bloqueando escaneos rápidos"
    return 1
  fi

  # Detección de IPS
  if proxychains4 -q nmap -Pn -T1 -p 80 --scan-delay 5s $target | grep -q "filtered"; then
    rgb "[⚠️] Sistema de prevención de intrusos detectado"
    return 1
  fi

  rgb "[✔] No se detectaron protecciones activas"
  return 0
}

# ===== ESCANEO POR ETAPAS =====
function staged_scan {
  target=$1
  rgb "[~] Selecciona estrategia de escaneo:"
  rgb "1) Escaneo Rápido (puertos comunes)"
  rgb "2) Escaneo Completo (todos los puertos)"
  rgb "3) Escaneo Sigiloso (evasión de WAF)"
  read -p "$(rgb "[?] Opción: ")" scan_type

  case $scan_type in
    1)
      ports=("20,21,22,23,25,53,80,110,143,443,445,993,995,3389,8080,8443")
      speed="-T4"
      delay="--max-scan-delay 1s"
      ;;
    2)
      ports=("1-10000")
      speed="-T3"
      delay="--max-scan-delay 3s"
      ;;
    3)
      ports=("20,21,22,80,443,3389,8080,8443")
      speed="-T1"
      delay="--scan-delay 5-15s"
      ;;
    *)
      ports=("20,21,22,80,443")
      speed="-T2"
      delay="--max-scan-delay 2s"
      ;;
  esac

  # Fase 1: Escaneo inicial
  rgb "[~] Fase 1: Escaneo inicial (${ports})..."
  proxychains4 -q nmap -Pn $speed --open $delay -p ${ports} $target -oN scan_phase1.log

  # Fase 2: Servicios detectados
  if grep -q "open" scan_phase1.log; then
    open_ports=$(grep "open" scan_phase1.log | awk -F'/' '{print $1}' | tr '\n' ',')
    rgb "[~] Fase 2: Analizando servicios (${open_ports})..."
    proxychains4 -q nmap -Pn -sV -O -p ${open_ports%,} $target -oN scan_phase2.log
  fi

  # Fase 3: Vulnerabilidades
  if [ -f "scan_phase2.log" ]; then
    rgb "[~] Fase 3: Buscando vulnerabilidades..."
    proxychains4 -q nmap -Pn --script vuln -p ${open_ports%,} $target -oN scan_phase3.log
  fi

  # Mostrar resultados consolidados
  rgb "[✔] Resultados consolidados:"
  [ -f "scan_phase1.log" ] && grep --color "open" scan_phase1.log
  [ -f "scan_phase3.log" ] && grep --color -E "VULNERABLE|CVE-" scan_phase3.log || rgb "[!] No se encontraron vulnerabilidades"
}

# ===== FUNCIÓN GLOBAL SCAN MEJORADA =====
function global_scan {
  read -p "$(rgb "[?] IP/Dominio a escanear: ")" target
  
  # Detección automática de protecciones
  if detect_protections "$target"; then
    rgb "[~] Iniciando escaneo estándar..."
    proxychains4 -q nmap -Pn -T4 --open -p- $target -oN retllax_scan.log
  else
    rgb "[~] Activando modo evasivo (WAF detectado)..."
    staged_scan "$target"
  fi
}

# [...] (El resto de funciones se mantienen igual: hydra_attack, metasploit_mod, check_deps, etc.)

# ===== MENÚ PRINCIPAL ACTUALIZADO =====
function main_menu {
  check_deps
  while true; do
    show_banner
    rgb "1) Escaneo Inteligente (Auto-detección)"
    rgb "2) Ataque Hydra Shadow"
    rgb "3) Módulo Metasploit"
    rgb "4) Ver Logs de Escaneo"
    rgb "5) Salir"
    echo
    read -p "$(rgb "[?] Elige una opción: ")" opt

    case $opt in
      1) global_scan ;;
      2) hydra_attack ;;
      3) metasploit_mod ;;
      4) 
        rgb "[📂] Logs disponibles:"
        ls -l scan_phase*.log retllax_*.log 2>/dev/null || rgb "[!] No hay logs disponibles"
        read -p "$(rgb "[?] Ingresa el nombre del log a ver: ")" logfile
        [ -f "$logfile" ] && cat "$logfile" | grep --color -E "open|VULNERABLE|CVE-|login:"
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
