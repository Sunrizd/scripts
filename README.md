# Mon Homelab - Scripts & Outils

Une collection de scripts personnels et d'outils d'automatisation pour le homelab.

## Structure du dépôt

### 🖥️ [proxmox/](file:///home/sunrizd/github/proxmox)
Scripts pour l'administration et la gestion de l'infrastructure Proxmox VE.

* **[list_proxmox_ips.sh](file:///home/sunrizd/github/proxmox/list_proxmox_ips.sh)** : Script Bash pour cartographier instantanément les adresses IPv4 de tout le cluster (nœuds, LXC, VMs).
  * 📘 [Documentation détaillée](file:///home/sunrizd/github/proxmox/list_proxmox_ips.md)

---

### 🦊 [forgejo/](file:///home/sunrizd/github/forgejo)
Scripts d'intégration et de synchronisation pour l'instance Forgejo/Gitea.

* **[github_sync.py](file:///home/sunrizd/github/forgejo/github_sync.py)** : Script Python pour automatiser la création et la synchronisation de miroirs de dépôts GitHub vers Forgejo.
  * 📘 [Documentation détaillée](file:///home/sunrizd/github/forgejo/github_sync.md)
