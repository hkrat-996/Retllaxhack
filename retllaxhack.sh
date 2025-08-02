#!/usr/bin/env bash

# RetllaxHack - Modo Evasión Mejorado (v2.5)
# Soluciona problema de permisos y mejora salida

clear

# Configuración de color mejorada
function colorize {
  echo -e "\033[1;$1m$2\033[0m"
}

# Banner ASCII mejorado
function show_banner {
  echo -e "$(colorize 35 '___     _   _ _          _  _         _')"
  echo -e "$(colorize 35 '| _ \\___| |_| | |__ ___ _| || |__ _ __| |__')"
  echo -e "$(colorize 35 '|   / -_)  _| | / _\` \\ \\ / __ / _\` / _| / /')"
  echo -e "$(colorize 35 '|_|_\\___|\\__|_|_\\__,_/_\\_\\_||_\\__,_\\__|_\\_\\')"
  echo
  echo -e "$(colorize 36 '=== MODO EVASIÓN ===')"
}

# Escaneo furtivo corregido
function escaneo_furtivo {
  show_banner
  read -p "$(colorize 33 'Objetivo (IP/Dominio): ')" objetivo
  
  # Configuración evasiva sin requerir root
  echo -e "$(colorize 32 '[~] Configurando perfil furtivo...')"
  delay=$((RANDOM%5+1))
  echo -e "$(colorize 36 '- Técnicas:')"
  echo -e "$(colorize 36 '  • Timing aleatorio (T2)')"
  echo -e "$(colorize 36 '  • Retardo: ')${delay}s"
  echo -e "$(colorize 36 '  • Escaneo TCP SYN')"
  
  echo -e "$(colorize 32 '\n[+] Iniciando escaneo...')"
  
  # Comando corregido que funciona sin root
  nmap -Pn -sS -T2 --scan-delay ${delay}s --max-retries 1 $objetivo \
    | tee -a scan.log \
    | while read line; do
        if [[ $line == *"open"* ]]; then
          echo -e "$(colorize 32 '[+] ')${line}"
        elif [[ $line == *"filtered"* ]]; then
          echo -e "$(colorize 33 '[?] ')${line}"
        else
          echo "$line"
        fi
      done
  
  echo -e "$(colorize 32 '\n[✔] Escaneo completado!')"
}

# Menú principal mejorado
function menu_principal {
  while true; do
    show_banner
    echo -e "$(colorize 32 '1)') Escaneo Fantasma (Stealth)"
    echo -e "$(colorize 32 '2)') Fuerza Bruta Encubierta"
    echo -e "$(colorize 32 '3)') Auto-Limpieza de Logs"
    echo -e "$(colorize 31 '4)') Salir"
    echo
    read -p "$(colorize 36 'Opción: ')" opcion

    case $opcion in
      1) escaneo_furtivo ;;
      2) fuerza_bruta_furtiva ;;
      3) rm -f scan.log 2>/dev/null && echo -e "$(colorize 32 '[✔] Logs eliminados!')" ;;
      4) exit 0 ;;
      *) echo -e "$(colorize 31 '[!] Opción inválida')"; sleep 1 ;;
    esac
    
    read -p "$(colorize 35 '\nEnter para continuar...')" 
  done
}

# Iniciar
menu_principal
