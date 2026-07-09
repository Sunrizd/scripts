# Proxmox VE Cluster IP Inventory

Un script Bash léger et ultra-rapide pour cartographier instantanément les adresses IPv4 de ton réseau local utilisées sur l'ensemble d'un cluster Proxmox (PVE).

Il s'appuie sur un appel unique à l'API Proxmox pour lister l'intégralité des ressources en moins d'une seconde, sans latence séquentielle, même avec des dizaines de machines.

## ⚙️ Fonctionnalités

* **Hyperviseurs :** Remonte proprement l'IP d'administration physique de chaque nœud du cluster.
* **Conteneurs LXC :** Identifie le mode réseau `[Static]` ou `[DHCP]` et extrait l'IP en temps réel.
* **Machines Virtuelles :** Interroge récursivement le QEMU Guest Agent pour cibler les interfaces d'origine.
* **Filtrage strict du bruit :** Nettoie automatiquement les loopbacks (`127.0.0.1`), masque Tailscale/Headscale, et élimine tout le flood des cartes réseaux virtuelles de Docker (`veth*`, `br-*`, `docker0`).
* **Indication des états :** Grise visuellement les instances arrêtées avec un tag `💤 (éteinte/éteint)` pour ne garder le focus que sur la production active.
* **Option de tri global :** Un paramètre permet de lister toutes les IPs du cluster par ordre croissant pour détecter les conflits en un coup d'œil.

## 🚀 Utilisation

Exécute le script directement depuis le shell root de n'importe quel nœud de ton cluster :

```bash
# 1. Récupérer le script
curl -O [https://raw.githubusercontent.com/Sunrizd/scripts/refs/heads/main/proxmox/list_proxmox_ips.sh](https://raw.githubusercontent.com/Sunrizd/scripts/refs/heads/main/proxmox/list_proxmox_ips.sh)

# 2. Rendre exécutable
chmod +x list_proxmox_ips.sh

# 3. Lancer l'affichage classique (par nœuds, conteneurs et VMs)
./list_proxmox_ips.sh

# 4. Lancer le tri par ordre croissant d'adresses IP
./list_proxmox_ips.sh -s
# ou
./list_proxmox_ips.sh --sort
```

## 🛠️ Dépendances

Le script utilise les outils natifs de l'écosystème Proxmox et un utilitaire classique :

* `pve-manager` (pour `pvesh` et `pvecm`)
* `jq` (requis pour parser le JSON de l'API globale) -> `apt install jq`

## 💡 Configuration requise pour les VMs

Pour que les adresses réseau de tes machines virtuelles remontent, le **QEMU Guest Agent** doit obligatoirement être coché dans les *Options* de la VM sous PVE, et le service correspondant doit tourner à l'intérieur du système invité (`systemctl start qemu-guest-agent`).
