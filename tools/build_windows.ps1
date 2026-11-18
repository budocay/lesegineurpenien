# Construit le jeu en version finale pour Windows, macOS et Linux, dans le dossier build\.
# Au premier lancement, télécharge les modèles d'export de Godot 4.7.2 (1,2 Go, une seule fois).
param([string]$Quoi = "tout")
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$version = "4.7.2"
$racine = Split-Path -Parent $PSScriptRoot
$godot = Join-Path $PSScriptRoot "godot\Godot_v$version-stable_win64_console.exe"
if (-not (Test-Path $godot)) {
    & (Join-Path $PSScriptRoot "installer_windows.ps1")
    if (-not (Test-Path $godot)) { Write-Host "Godot introuvable." -ForegroundColor Red; exit 1 }
}
$modeles = Join-Path $env:APPDATA "Godot\export_templates\$version.stable"
if (-not (Test-Path (Join-Path $modeles "version.txt"))) {
    Write-Host "Téléchargement des modèles d'export de Godot $version (1,2 Go)..."
    $tmp = Join-Path $env:TEMP "godot_modeles_$version"
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    $zip = Join-Path $tmp "modeles.zip"
    # curl.exe (fourni avec Windows 10 et 11) affiche une barre de progression ; sinon repli silencieux
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -L --fail --progress-bar -o $zip "https://github.com/godotengine/godot/releases/download/$version-stable/Godot_v$version-stable_export_templates.tpz"
        if ($LASTEXITCODE -ne 0) { Write-Host "Le téléchargement a échoué." -ForegroundColor Red; exit 1 }
    } else {
        Write-Host "(pas de barre de progression sur cette machine : patienter, la fenêtre ne bouge pas pendant le téléchargement)"
        Invoke-WebRequest -Uri "https://github.com/godotengine/godot/releases/download/$version-stable/Godot_v$version-stable_export_templates.tpz" -OutFile $zip -UseBasicParsing
    }
    Write-Host "Décompression des modèles (une à deux minutes)..."
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    New-Item -ItemType Directory -Force -Path $modeles | Out-Null
    Move-Item -Path (Join-Path $tmp "templates\*") -Destination $modeles -Force
    Remove-Item -Recurse -Force $tmp
}
Write-Host "Préparation du projet..."
Start-Process -FilePath $godot -ArgumentList @("--headless", "--path", "`"$racine`"", "--import") -Wait -NoNewWindow | Out-Null
$cibles = @(
    @{ nom = "windows"; preset = "Windows"; fichier = "build\windows\SeigneurDesAnneauxPeniens.exe" },
    @{ nom = "macos";   preset = "macOS";   fichier = "build\macos\SeigneurDesAnneauxPeniens.zip" },
    @{ nom = "linux";   preset = "Linux";   fichier = "build\linux\SeigneurDesAnneauxPeniens.x86_64" }
)
$echec = $false
foreach ($c in $cibles) {
    if ($Quoi -ne "tout" -and $Quoi -ne $c.nom) { continue }
    $sortie = Join-Path $racine $c.fichier
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $sortie) | Out-Null
    Write-Host "== $($c.preset) == (une à trois minutes, la fenêtre reste muette pendant ce temps)"
    Start-Process -FilePath $godot -ArgumentList @("--headless", "--path", "`"$racine`"", "--export-release", $c.preset, "`"$sortie`"") -Wait -NoNewWindow | Out-Null
    if ((Test-Path $sortie) -and ((Get-Item $sortie).Length -gt 0)) { Write-Host "   fait : $sortie" -ForegroundColor Green }
    else { Write-Host "   ECHEC : $sortie n'a pas été produit" -ForegroundColor Red; $echec = $true }
}
if ($echec) { exit 1 }
Write-Host "Terminé : voir le dossier build\" -ForegroundColor Green
