#!/bin/bash
# DNSTM Ultimate Panel (TUI)
# Advanced Tunnel Manager

CONFIG_DIRS=("/etc/dnstm" "/var/lib/dnstm" "/opt/dnstm")
SERVICE_PATTERN="dnstm"

color() { echo -e "\e[$1m$2\e[0m"; }

header() {
  clear
  color 36 "========================================"
  color 36 "        DNSTM Advanced Panel"
  color 36 "========================================"
}

list_tunnels() {
  color 33 "[Tunnels List]"
  systemctl list-units --type=service | grep dnstm | awk '{print NR" - "$1" ("$4")"}'
}

show_details() {
  read -p "Enter service name: " svc
  systemctl status "$svc"
  echo "\n--- Exec Info ---"
  systemctl cat "$svc" | grep ExecStart
}

restart_tunnel() {
  read -p "Service: " svc
  systemctl restart "$svc" && color 32 "Restarted"
}

stop_tunnel() {
  read -p "Service: " svc
  systemctl stop "$svc" && color 31 "Stopped"
}

start_tunnel() {
  read -p "Service: " svc
  systemctl start "$svc" && color 32 "Started"
}

remove_tunnel() {
  read -p "Service: " svc
  systemctl stop "$svc"
  rm -f "/etc/systemd/system/$svc.service"
  systemctl daemon-reexec
  color 31 "Removed"
}

live_monitor() {
  read -p "Service: " svc
  journalctl -u "$svc" -f
}

export_json() {
  OUT="dnstm_$(date +%s).json"
  echo "[" > $OUT

  first=true
  for svc in $(systemctl list-units --type=service | grep dnstm | awk '{print $1}'); do
    cmd=$(systemctl cat "$svc" | grep ExecStart | sed 's/ExecStart=//')

    $first || echo "," >> $OUT
    first=false

    echo "{\"service\":\"$svc\",\"cmd\":\"$cmd\"}" >> $OUT
  done

  echo "]" >> $OUT
  color 32 "Saved: $OUT"
}

search_configs() {
  for dir in "${CONFIG_DIRS[@]}"; do
    [ -d "$dir" ] && find "$dir" -type f
  done
}

create_tunnel_helper() {
  color 34 "[Manual Tunnel Helper]"
  read -p "Domain: " domain
  read -p "Port: " port
  read -p "Type (dnstt/slip): " type

  echo "Use these values in original script:"
  echo "Domain: $domain"
  echo "Port: $port"
  echo "Type: $type"
}

menu() {
  header
  echo "1) List Tunnels"
  echo "2) Show Details"
  echo "3) Start Tunnel"
  echo "4) Stop Tunnel"
  echo "5) Restart Tunnel"
  echo "6) Remove Tunnel"
  echo "7) Live Monitor"
  echo "8) Export JSON"
  echo "9) Scan Config Files"
  echo "10) Create Tunnel Helper"
  echo "0) Exit"
}

while true; do
  menu
  read -p "Select: " opt

  case $opt in
    1) list_tunnels ;;
    2) show_details ;;
    3) start_tunnel ;;
    4) stop_tunnel ;;
    5) restart_tunnel ;;
    6) remove_tunnel ;;
    7) live_monitor ;;
    8) export_json ;;
    9) search_configs ;;
    10) create_tunnel_helper ;;
    0) exit ;;
    *) echo "Invalid" ;;
  esac

  echo
  read -p "Enter to continue..."
done
