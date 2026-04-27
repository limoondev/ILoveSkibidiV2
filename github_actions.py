"""
ILoveSkibidi V2 - GitHub Actions DMG Builder & Downloader
Ce script initialise le repo git, crée le workflow GitHub Actions, et télécharge le DMG après le build.
"""

import os
import sys
import subprocess
import time
import requests
from pathlib import Path

# Configuration
REPO_NAME = "ILoveSkibidiV2"
WORKFLOW_FILE = ".github/workflows/build-dmg.yml"
PROJECT_ROOT = Path(__file__).parent

def run_command(cmd, cwd=None):
    """Exécute une commande shell."""
    print(f"➜ Exécution: {cmd}")
    result = subprocess.run(cmd, shell=True, cwd=cwd or PROJECT_ROOT, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"✗ Erreur: {result.stderr}")
        return False
    print(f"✓ Succès")
    return True

def init_git_repo():
    """Initialise le repository git."""
    print("\n=== Initialisation du repository Git ===")
    
    git_dir = PROJECT_ROOT / ".git"
    if not git_dir.exists():
        if not run_command("git init"):
            return False
    
    # Vérifier s'il y a déjà un commit
    result = subprocess.run(
        "git rev-parse HEAD",
        shell=True,
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True
    )
    
    if result.returncode == 0:
        print("✓ Repository git déjà initialisé avec commit")
    else:
        print("  Ajout des fichiers...")
        if not run_command("git add ."):
            return False
        print("  Création du commit initial...")
        if not run_command('git commit -m "Initial commit: ILoveSkibidi V2 macOS app"'):
            return False
    
    print("✓ Repository git prêt")
    return True

def create_github_repo(token, username):
    """Crée le repository GitHub via API."""
    print(f"\n=== Création du repository GitHub ===")
    
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    # Vérifier si le repo existe déjà
    response = requests.get(
        f"https://api.github.com/repos/{username}/{REPO_NAME}",
        headers=headers
    )
    
    if response.status_code == 200:
        print(f"✓ Repository {username}/{REPO_NAME} existe déjà")
        return f"https://github.com/{username}/{REPO_NAME}.git"
    
    # Créer le repo
    data = {
        "name": REPO_NAME,
        "description": "ILoveSkibidi V2 - Application macOS premium avec correction de texte, import Notability et scanner",
        "private": False,
        "auto_init": False
    }
    
    response = requests.post(
        f"https://api.github.com/user/repos",
        headers=headers,
        json=data
    )
    
    if response.status_code == 201:
        print(f"✓ Repository {username}/{REPO_NAME} créé")
        return f"https://github.com/{username}/{REPO_NAME}.git"
    else:
        print(f"✗ Erreur création repo: {response.text}")
        return None

def push_to_github(repo_url):
    """Push le code vers GitHub."""
    print(f"\n=== Push vers GitHub ===")
    
    # Supprimer l'origin existant s'il y en a un
    result = subprocess.run(
        "git remote get-url origin",
        shell=True,
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True
    )
    
    if result.returncode == 0:
        current_url = result.stdout.strip()
        if current_url != repo_url:
            print("  Mise à jour de l'origin...")
            run_command(f'git remote set-url origin "{repo_url}"')
        else:
            print("  Origin déjà configuré")
    else:
        print("  Ajout de l'origin...")
        run_command(f'git remote add origin "{repo_url}"')
    
    # S'assurer que la branche main existe
    run_command("git branch -M main")
    
    # Push avec force pour être sûr
    run_command("git push -u origin main --force")
    
    print("✓ Code pushé vers GitHub")

def trigger_workflow(token, username):
    """Déclenche le workflow GitHub Actions."""
    print(f"\n=== Déclenchement du workflow GitHub Actions ===")
    
    # Attendre un peu que GitHub traite le push
    print("  Attente du traitement du push par GitHub (5s)...")
    time.sleep(5)
    
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    response = requests.post(
        f"https://api.github.com/repos/{username}/{REPO_NAME}/actions/workflows/build-dmg.yml/dispatches",
        headers=headers,
        json={"ref": "main"}
    )
    
    if response.status_code == 204:
        print("✓ Workflow déclenché")
        return True
    else:
        print(f"✗ Erreur déclenchement: {response.text}")
        return False

def wait_for_workflow_completion(token, username, max_wait_minutes=15):
    """Attend la fin du workflow."""
    print(f"\n=== Attente du build (max {max_wait_minutes} minutes) ===")
    
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    start_time = time.time()
    check_interval = 30
    
    while time.time() - start_time < max_wait_minutes * 60:
        response = requests.get(
            f"https://api.github.com/repos/{username}/{REPO_NAME}/actions/runs?per_page=1",
            headers=headers
        )
        
        if response.status_code == 200:
            data = response.json()
            if data["workflow_runs"]:
                run = data["workflow_runs"][0]
                status = run["status"]
                conclusion = run.get("conclusion", "in_progress")
                
                print(f"  Status: {status} | Conclusion: {conclusion}")
                
                if status == "completed":
                    if conclusion == "success":
                        print("✓ Build terminé avec succès")
                        return run["id"]
                    else:
                        print(f"✗ Build échoué: {conclusion}")
                        return None
        
        time.sleep(check_interval)
    
    print("✗ Timeout - build trop long")
    return None

def download_artifact(token, username, run_id, output_dir="downloads"):
    """Télécharge l'artifact DMG."""
    print(f"\n=== Téléchargement du DMG ===")
    
    output_path = Path(output_dir)
    output_path.mkdir(exist_ok=True)
    
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    # Lister les artifacts
    response = requests.get(
        f"https://api.github.com/repos/{username}/{REPO_NAME}/actions/runs/{run_id}/artifacts",
        headers=headers
    )
    
    if response.status_code != 200:
        print(f"✗ Erreur récupération artifacts: {response.text}")
        return None
    
    data = response.json()
    if not data["artifacts"]:
        print("✗ Aucun artifact trouvé")
        return None
    
    artifact = data["artifacts"][0]
    print(f"  Artifact trouvé: {artifact['name']}")
    
    # Télécharger l'artifact
    download_response = requests.get(
        artifact["archive_download_url"],
        headers=headers
    )
    
    if download_response.status_code != 200:
        print("✗ Erreur téléchargement")
        return None
    
    zip_path = output_path / f"{artifact['name']}.zip"
    with open(zip_path, "wb") as f:
        f.write(download_response.content)
    
    print(f"✓ Artifact téléchargé: {zip_path}")
    
    # Extraire le ZIP
    print("  Extraction du ZIP...")
    import zipfile
    with zipfile.ZipFile(zip_path, "r") as zip_ref:
        zip_ref.extractall(output_path)
    
    # Trouver le DMG
    dmg_files = list(output_path.glob("*.dmg"))
    if dmg_files:
        dmg_path = dmg_files[0]
        print(f"✓ DMG extrait: {dmg_path}")
        
        # Nettoyer le ZIP
        zip_path.unlink()
        
        return dmg_path
    
    return None

def main():
    print("=== ILoveSkibidi V2 - GitHub Actions DMG Builder ===\n")
    
    # Vérifier les dépendances
    try:
        import requests
    except ImportError:
        print("✗ Installation de requests...")
        subprocess.run([sys.executable, "-m", "pip", "install", "requests"])
    
    # Demander les credentials GitHub
    print("Veuillez entrer vos credentials GitHub:")
    username = input("GitHub Username: ").strip()
    token = input("GitHub Personal Access Token (with repo permissions): ").strip()
    
    if not username or not token:
        print("✗ Credentials manquants")
        sys.exit(1)
    
    # Étape 1: Initialiser git
    if not init_git_repo():
        sys.exit(1)
    
    # Étape 2: Créer le repo GitHub
    repo_url = create_github_repo(token, username)
    if not repo_url:
        sys.exit(1)
    
    # Étape 3: Push vers GitHub
    push_to_github(repo_url)
    
    # Étape 4: Déclencher le workflow
    if not trigger_workflow(token, username):
        sys.exit(1)
    
    # Étape 5: Attendre le build
    run_id = wait_for_workflow_completion(token, username)
    if not run_id:
        sys.exit(1)
    
    # Étape 6: Télécharger le DMG
    dmg_path = download_artifact(token, username, run_id)
    if dmg_path:
        print(f"\n🎉 SUCCÈS! DMG disponible à: {dmg_path.absolute()}")
    else:
        print("\n✗ Échec du téléchargement du DMG")
        sys.exit(1)

if __name__ == "__main__":
    main()
