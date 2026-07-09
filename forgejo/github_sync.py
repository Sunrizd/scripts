import requests
import json
import os
import sys

# --- CONFIGURATION VIA VARIABLES D'ENVIRONNEMENT ---
GITHUB_USERNAME = os.getenv("GITHUB_USERNAME", "TON_PSEUDO_PAR_DEFAUT")
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
FORGEJO_URL = os.getenv("FORGEJO_URL", "http://localhost:3000")
FORGEJO_TOKEN = os.getenv("FORGEJO_TOKEN")

if not GITHUB_TOKEN or not FORGEJO_TOKEN:
    print("❌ Erreur : GITHUB_TOKEN et FORGEJO_TOKEN doivent être définis dans l'environnement.")
    sys.exit(1)
# ---------------------------------------------------

headers_gh = {"Authorization": f"token {GITHUB_TOKEN}"}
headers_fj = {"Authorization": f"token {FORGEJO_TOKEN}", "Content-Type": "application/json"}

# 1. Récupérer tous les dépôts GitHub (Publics et Privés)
print("🔍 Récupération des dépôts depuis GitHub...")
gh_repos = []
page = 1
while True:
    url = f"https://api.github.com/user/repos?per_page=100&page={page}"
    response = requests.get(url, headers=headers_gh).json()
    if not response or 'message' in response:
        break
    gh_repos.extend(response)
    page += 1

# 2. Récupérer la liste de TOUS les dépôts Forgejo ayant un miroir actif
print("📦 Récupération et vérification des miroirs existants sur Forgejo...")
fj_mirror_names = []
page_fj = 1

while True:
    response_fj = requests.get(f"{FORGEJO_URL}/api/v1/repos/search?uid=0&page={page_fj}&limit=50", headers=headers_fj)
    
    if response_fj.status_code != 200:
        print(f"❌ Erreur de connexion à Forgejo (Code {response_fj.status_code}) : {response_fj.text}")
        exit(1)
        
    data_fj = response_fj.json()
    if not data_fj or "data" not in data_fj or not data_fj["data"]:
        break
        
    for repo in data_fj["data"]:
        # On vérifie si le dépôt est marqué comme miroir dans Forgejo
        if repo.get("mirror", False) or repo.get("mirror_interval", "") != "":
            fj_mirror_names.append(repo['name'].lower())
        else:
            print(f"⚠️  Dépôt trouvé sans miroir actif : {repo['name']} (Sera traité si présent sur GitHub)")
        
    page_fj += 1

# 3. Comparer et importer uniquement si le miroir n'existe pas
for repo in gh_repos:
    name = repo['name']
    if repo['owner']['login'].lower() != GITHUB_USERNAME.lower():
        continue
        
    if name.lower() not in fj_mirror_names:
        print(f"🚀 Configuration du miroir automatique pour : {name}")
        
        payload = {
            "clone_addr": repo['clone_url'],
            "mirror": True,
            "repo_name": name,
            "private": repo['private'],
            "description": repo['description'] or f"Miroir automatique de {name}",
            "auth_token": GITHUB_TOKEN
        }
        
        res = requests.post(f"{FORGEJO_URL}/api/v1/repos/migrate", headers=headers_fj, json=payload)
        if res.status_code == 201:
            print(f"✅ {name} est maintenant synchronisé en mode miroir.")
        elif res.status_code == 422 and "already exists" in res.text:
            print(f"ℹ️  Le dépôt {name} existe déjà mais sa configuration locale bloque l'API.")
        else:
            print(f"❌ Erreur lors de la migration de {name} : {res.text}")
    else:
        print(f"✨ Le miroir de {name} est déjà actif et opérationnel.")
