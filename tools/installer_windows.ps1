# Le Seigneur des Anneaux Péniens : installation pour Windows.
# Télécharge Godot 4.7.2 (version exacte utilisée pour construire le jeu) dans tools\godot,
# puis prépare le projet. Rien n'est installé ailleurs sur la machine : supprimer le dossier
# tools\godot suffit pour tout enlever.
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
. (Join-Path $PSScriptRoot "outils_godot.ps1")

$version = "4.7.2-stable"
$racine = Split-Path -Parent $PSScriptRoot
$dossier = Join-Path $PSScriptRoot "godot"
$exe = Join-Path $dossier "Godot_v${version}_win64.exe"
$url = "https://github.com/godotengine/godot/releases/download/$version/Godot_v${version}_win64.exe.zip"

if (-not (Test-Path -LiteralPath (Join-Path $racine "project.godot"))) {
    Write-Host "project.godot introuvable : ce script doit rester dans le dossier tools du jeu." -ForegroundColor Red
    exit 1
}

# Un fichier présent mais incomplet (téléchargement coupé, antivirus) donne « CreateProcess failed, error 193 » :
# on ne s'en contente pas, on le vérifie.
if ((Test-Path -LiteralPath $exe) -and -not (Test-ExeWindows $exe)) {
    Write-Host "Le Godot déjà présent est incomplet ou corrompu : il est remplacé." -ForegroundColor Yellow
    Remove-Item -LiteralPath $exe -Force
}

if (Test-Path -LiteralPath $exe) {
    Write-Host "Godot $version est déjà installé."
} else {
    New-Item -ItemType Directory -Force -Path $dossier | Out-Null
    $zip = Join-Path $dossier "godot.zip"
    Write-Host "Téléchargement de Godot $version (environ 70 Mo)..."
    try { Get-Telechargement $url $zip } catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
    if ((Get-Item -LiteralPath $zip).Length -lt 30000000) {
        Write-Host "Le téléchargement est incomplet ($((Get-Item -LiteralPath $zip).Length) octets). Vérifier la connexion et relancer." -ForegroundColor Red
        Remove-Item -LiteralPath $zip -Force
        exit 1
    }
    Write-Host "Décompression..."
    Expand-Archive -LiteralPath $zip -DestinationPath $dossier -Force
    Remove-Item -LiteralPath $zip
    if (-not (Test-ExeWindows $exe)) {
        Write-Host "Godot a été décompressé dans $dossier mais le fichier n'est pas un programme Windows valide." -ForegroundColor Red
        Write-Host "Causes possibles : antivirus qui a mis le fichier en quarantaine, disque plein. Supprimer le dossier tools\godot, vérifier l'antivirus, relancer." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Préparation du jeu (une minute environ la première fois)..."
# Programme principal, pas la variante « console » (celle-ci relance le principal par son chemin et
# échoue avec « error 193 » si ce chemin pose problème). Dossier de travail = le jeu, chemins sans espace.
$code = Invoke-Godot $exe $racine @("--headless", "--path", ".", "--import") "installation_journal.txt"
if ($code -ne 0) {
    Write-Host "La préparation a renvoyé le code $code (détails dans installation_journal.txt). Le jeu se lancera peut-être quand même." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Installation terminée. Pour jouer : double-cliquer sur jouer.bat." -ForegroundColor Green
exit 0
