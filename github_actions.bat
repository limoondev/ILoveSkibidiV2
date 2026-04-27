@echo off
REM ILoveSkibidi V2 - GitHub Actions DMG Builder
REM Ce script lance le Python pour build et télécharger le DMG

echo === ILoveSkibidi V2 - GitHub Actions DMG Builder ===
echo.

REM Vérifier Python
python --version >nul 2>&1
if errorlevel 1 (
    echo Erreur: Python n'est pas installé ou pas dans le PATH
    echo Veuillez installer Python 3.8+ depuis https://python.org
    pause
    exit /b 1
)

REM Installer requests si nécessaire
echo Verification des dependences...
python -c "import requests" >nul 2>&1
if errorlevel 1 (
    echo Installation de requests...
    python -m pip install requests
)

REM Lancer le script Python
echo.
echo Lancement du script Python...
python github_actions.py

if errorlevel 1 (
    echo.
    echo Erreur lors de l'execution
    pause
    exit /b 1
)

echo.
echo === Termine ===
pause
