# GitHub to Forgejo Mirror Sync

Un script Python ultra-léger pour automatiser le mirroring de tes dépôts GitHub vers une instance Forgejo (ou Gitea) auto-hébergée.

Idéal pour le homelab : il tourne en tâche de fond (cron) et s'assure que dès que tu crées un dépôt public ou privé sur GitHub, un miroir local est instantanément configuré chez toi.

## Fonctionnalités

* **Zéro maintenance :** Détection automatique des nouveaux dépôts GitHub.
* **Miroirs dynamiques :** Ne fait pas un simple import unique, il configure Forgejo en mode pull-mirror (synchro continue).
* **Support des Organisations :** Gère aussi bien tes dépôts personnels que ceux hébergés dans des organisations Forgejo.
* **Sécurisé :** Aucune clé ou jeton n'est stocké en dur dans le code (utilisation de variables d'environnement).

## Prérequis

* Python 3.x
* Le module `requests` (`pip install requests`)
* Un Personal Access Token (PAT) **GitHub** avec le scope `repo`
* Un jeton d'accès **Forgejo** avec les droits d'écriture (`repository` et `user`)

## Configuration & Usage

Le script s'appuie entièrement sur les variables d'environnement pour des raisons de sécurité.

### Test manuel rapide

```bash
GITHUB_USERNAME="ton_pseudo" \
GITHUB_TOKEN="ghp_ton_token_github" \
FORGEJO_TOKEN="fj_ton_token_forgejo" \
FORGEJO_URL="http://localhost:3000" \
python3 github_sync.py

```

## Automatisation (Cron)

Pour automatiser la détection (par exemple, toutes les heures), ajoute le script à la crontab de ton utilisateur `git` (ou de l'utilisateur qui gère Forgejo dans ton LXC).

Ouvre la crontab :

```bash
crontab -e

```

Ajoute la ligne suivante en adaptant tes jetons et le chemin absolu du script :

```text
0 * * * * GITHUB_USERNAME="ton_pseudo" GITHUB_TOKEN="ghp_xxx" FORGEJO_TOKEN="fj_xxx" FORGEJO_URL="http://localhost:3000" python3 /home/git/github_sync.py > /dev/null 2>&1

```
