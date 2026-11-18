# Le Seigneur des Anneaux Péniens : installation pour Windows.
# Télécharge Godot 4.7.2 (version exacte utilisée pour construire le jeu) dans tools\godot,
# puis prépare le projet. Rien n'est installé ailleurs sur la machine : supprimer le dossier
# tools\godot suffit pour tout enlever.
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$version = "4.7.2-stable"
$racine = Split-Path -Parent $PSScriptRoot
$dossier = Join-Path $PSScriptRoot "godot"
$exe = Join-Path $dossier "Godot_v${version}_win64.exe"
$console = Join-Path $dossier "Godot_v${version}_win64_console.exe"
$url = "https://github.com/godotengine/godot/releases/download/$version/Godot_v${version}_win64.exe.zip"

if (-not (Test-Path (Join-Path $racine "project.godot"))) {
    Write-Host "project.godot introuvable : ce script doit rester dans le dossier tools du jeu." -ForegroundColor Red
    exit 1
}

if (Test-Path $exe) {
    Write-Host "Godot $version est déjà installé."
} else {
    New-Item -ItemType Directory -Force -Path $dossier | Out-Null
    $zip = Join-Path $dossier "godot.zip"
    Write-Host "Téléchargement de Godot $version (environ 70 Mo)..."
    # curl.exe (fourni avec Windows 10 et 11) affiche une barre de progression ; sinon repli silencieux
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -L --fail --progress-bar -o $zip $url
        if ($LASTEXITCODE -ne 0) { Write-Host "Le téléchargement a échoué." -ForegroundColor Red; exit 1 }
    } else {
        Write-Host "(pas de barre de progression sur cette machine : patienter, la fenêtre ne bouge pas pendant le téléchargement)"
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    }
    Write-Host "Décompression..."
    Expand-Archive -Path $zip -DestinationPath $dossier -Force
    Remove-Item $zip
    if (-not (Test-Path $exe)) {
        Write-Host "Godot n'a pas été trouvé après décompression dans $dossier." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Préparation du jeu (une minute environ la première fois)..."
# Programme principal, pas la variante « console » : celle-ci échoue quand le chemin contient une espace.
$outil = $exe
$p = Start-Process -FilePath $outil -ArgumentList @("--headless", "--path", "`"$racine`"", "--import") -Wait -PassThru -NoNewWindow
if ($p.ExitCode -ne 0) {
    Write-Host "La préparation a renvoyé le code $($p.ExitCode). Le jeu se lancera peut-être quand même." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Installation terminée. Pour jouer : double-cliquer sur jouer.bat." -ForegroundColor Green
exit 0
