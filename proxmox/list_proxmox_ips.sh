#!/bin/bash

if ! command -v jq &> /dev/null; then
    echo "❌ Erreur : 'jq' est requis."
    exit 1
fi

RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
GRAY="\033[90m"

# Mode de tri (false par défaut)
SORT_BY_IP=false
[[ "$1" == "--sort" || "$1" == "-s" ]] && SORT_BY_IP=true

color_ip() {
    [[ $1 =~ ^192\.168\. ]] && echo -e "${GREEN}$1${RESET}" || echo -e "$1"
}

TMP_ALL=$(mktemp)

echo "=================================================="
echo "   🌐 INVENTAIRE DES IPS DU CLUSTER PROXMOX   "
echo "=================================================="

# 1. Extraction des Nodes
echo -e "\n🖥️  [NŒUDS DU CLUSTER]"
pvecm nodes | awk '$1 ~ /^[0-9]+$/ {print $3}' | while read -r node; do
    node_ip=$(getent hosts "$node" | awk '{print $1}' | head -n 1)
    [ -z "$node_ip" ] && node_ip=$(pvesh get /nodes/$node/network --output-format json 2>/dev/null | jq -r '.[] | select(.address != null and .active == 1) | .address' | grep '^192\.168\.1\.' | head -n 1)
    
    if [ "$SORT_BY_IP" = true ]; then
        echo "${node_ip} | 🖥️  Node [${node}]" >> "$TMP_ALL"
    else
        echo -e "   🔹 ${BOLD}${node}${RESET} -> $(color_ip ${node_ip})"
    fi
done

# 2. APPEL UNIQUE API : Récupère TOUT le cluster d'un coup (LXC + VMs)
CLUSTER_DATA=$(pvesh get /cluster/resources --type vm --output-format json 2>/dev/null)

# 3. Traitement des LXC
if [ "$SORT_BY_IP" = false ]; then echo -e "\n📦 [CONTENEURS LXC]"; fi
while read -r vmid node name status; do
    [ -z "$vmid" ] && continue
    is_dhcp=$(grep -E 'net[0-9]+:' "/etc/pve/nodes/$node/lxc/$vmid.conf" 2>/dev/null | grep -q 'ip=dhcp' && echo "oui" || echo "non")
    
    if [ "$status" == "running" ]; then
        ips=$(pvesh get /nodes/$node/lxc/$vmid/interfaces --output-format json 2>/dev/null | jq -r '.[] | select(.name != "lo") | .inet // empty' | cut -d/ -f1 | grep '^192\.168\.' | tr '\n' ' ')
    else
        ips=$(grep -E 'net[0-9]+:' "/etc/pve/nodes/$node/lxc/$vmid.conf" 2>/dev/null | grep -oE 'ip=[0-9./]+' | cut -d= -f2 | grep '^192\.168\.' | tr '\n' ' ')
    fi

    if [ "$SORT_BY_IP" = true ]; then
        for ip in $ips; do echo "${ip} | 📦 LXC $vmid [$name] (${node})" >> "$TMP_ALL"; done
    else
        if [ "$status" == "running" ]; then
            net_type="[${GREEN}Static${RESET}]"; [ "$is_dhcp" == "oui" ] && net_type="[${CYAN}DHCP${RESET}]"
            colored_ips=""
            for ip in $ips; do colored_ips+="$(color_ip $ip) "; done
            [ -z "$ips" ] && colored_ips="${YELLOW}⚠️ (Aucune IP LAN)${RESET}"
            echo -e "   🔸 CT $vmid [$name] sur $node -> $net_type $colored_ips"
        else
            # Rendu uniforme pour les conteneurs éteints
            echo -e "   🔸 CT $vmid [$name] sur $node -> ${GRAY}💤 (CT éteint)${RESET}"
        fi
    fi
done < <(echo "$CLUSTER_DATA" | jq -r '.[] | select(.type=="lxc") | "\(.vmid) \(.node) \(.name) \(.status)"')

# 4. Traitement des VMs
if [ "$SORT_BY_IP" = false ]; then echo -e "\n🚀 [MACHINES VIRTUELLES (VMs)]"; fi
while read -r vmid node name status; do
    [ -z "$vmid" ] && continue
    if [ "$status" == "running" ]; then
        raw_ips=$(pvesh get /nodes/$node/qemu/$vmid/agent/network-get-interfaces --output-format json 2>/dev/null | \
            jq -r '.result[]? | select(.name != "lo" and (.name | startswith("veth") | not) and (.name | startswith("br-") | not) and (.name | startswith("docker") | not)) | .["ip-addresses"][]? | select(.["ip-address-type"] == "ipv4") | .["ip-address"]' 2>/dev/null | \
            grep '^192\.168\.')
        
        if [ "$SORT_BY_IP" = true ]; then
            for ip in $raw_ips; do echo "${ip} | 🚀 VM $vmid [$name] (${node})" >> "$TMP_ALL"; done
        else
            output_ips=""
            for ip in $raw_ips; do output_ips+="$(color_ip $ip) "; done
            [ -z "$output_ips" ] && output_ips="${YELLOW}⚠️  (Pas d'IP LAN / Agent non prêt)${RESET}"
            echo -e "   🔹 VM $vmid [$name] sur $node -> $output_ips"
        fi
    elif [ "$SORT_BY_IP" = false ]; then
        echo -e "   🔹 VM $vmid [$name] sur $node -> ${GRAY}💤 (VM éteinte)${RESET}"
    fi
done < <(echo "$CLUSTER_DATA" | jq -r '.[] | select(.type=="qemu") | "\(.vmid) \(.node) \(.name) \(.status)"')

# --- 5. AFFICHAGE SI MODE TRI ---
if [ "$SORT_BY_IP" = true ]; then
    echo -e "\n📊 [TRI PAR ADRESSE IP CROISSANTE - SANS VPN / SANS DOCKER]"
    sort -V "$TMP_ALL" | grep -v '^ ' | while read -r line; do
        ip=$(echo "$line" | cut -d'|' -f1 | tr -d ' ')
        details=$(echo "$line" | cut -d'|' -f2-)
        echo -e "   ➡️  $(color_ip $ip) -> $details"
    done
fi

rm -f "$TMP_ALL"
echo -e "\n=================================================="
