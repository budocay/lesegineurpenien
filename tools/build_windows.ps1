# Construit le jeu (Windows, macOS, Linux) et prépare les archives à envoyer, dans le dossier build\.
#   build.bat                 les trois plateformes
#   build.bat windows         une seule (windows, macos ou linux)
#   build.bat tout -Test      lance d'abord le test rapide : rien n'est construit s'il échoue
# La version se lit dans project.godot (application/config/version).
# Au premier lancement, télécharge les modèles d'export de Godot 4.7.2 (1,2 Go, une seule fois).
param([string]$Quoi = "tout", [switch]$Test)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
. (Join-Path $PSScriptRoot "outils_godot.ps1")

$godotVersion = "4.7.2"
$nom = "SeigneurDesAnneauxPeniens"
$racine = Split-Path -Parent $PSScriptRoot
$paquet = Join-Path $PSScriptRoot "paquet"
$sansBom = New-Object System.Text.UTF8Encoding($false)
$avecBom = New-Object System.Text.UTF8Encoding($true)

function Stop-Build([string]$message) {
    Write-Host ""
    Write-Host "ERREUR : $message" -ForegroundColor Red
    exit 1
}
if ($Quoi -notin @("tout", "windows", "macos", "linux")) { Stop-Build "argument inconnu « $Quoi » (attendu : tout, windows, macos, linux)" }

try { $version = Get-VersionJeu $racine } catch { Stop-Build $_.Exception.Message }
$version4 = "$version.0"
$build = Join-Path $racine "build"
New-Item -ItemType Directory -Force -Path $build | Out-Null
$journal = "build\journal_godot.txt"          # écrit par Godot, relatif au dossier du jeu (sans espace)
$journalBuild = Join-Path $build "journal_build.txt"
Set-Content -Path $journalBuild -Value "Construction de la version $version, $(Get-Date)" -Encoding UTF8
Write-Host "Le Seigneur des Anneaux Péniens : construction de la version $version"
Write-Host "(journaux : build\journal_build.txt et build\journal_godot.txt)"

# --- Godot : programme principal (pas la variante « console ») ------------------------
# Il est installé dans tools\godot par installer_windows.ps1. Un fichier incomplet ou corrompu
# produit « CreateProcess failed, error 193 » : on le vérifie, et on le retélécharge si besoin.
$godot = Join-Path $PSScriptRoot "godot\Godot_v$godotVersion-stable_win64.exe"
if (-not (Test-ExeWindows $godot)) {
    if (Test-Path -LiteralPath $godot) { Write-Host "Le fichier Godot est incomplet ou corrompu : nouvelle installation." -ForegroundColor Yellow; Remove-Item -LiteralPath $godot -Force }
    & (Join-Path $PSScriptRoot "installer_windows.ps1")
    if (-not (Test-ExeWindows $godot)) { Stop-Build "Godot est introuvable ou invalide : $godot (supprimer le dossier tools\godot puis relancer)" }
}

# --- modèles d'export -------------------------------------------------------------------
$modeles = Join-Path $env:APPDATA "Godot\export_templates\$godotVersion.stable"
if (-not (Test-Path -LiteralPath (Join-Path $modeles "version.txt"))) {
    Write-Host "Téléchargement des modèles d'export de Godot $godotVersion (1,2 Go, une seule fois)..."
    $tmp = Join-Path $env:TEMP "godot_modeles_$godotVersion"
    if (Test-Path -LiteralPath $tmp) { Remove-Item -Recurse -Force -LiteralPath $tmp }
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    $zipModeles = Join-Path $tmp "modeles.zip"
    try { Get-Telechargement "https://github.com/godotengine/godot/releases/download/$godotVersion-stable/Godot_v$godotVersion-stable_export_templates.tpz" $zipModeles } catch { Stop-Build $_.Exception.Message }
    if ((Get-Item -LiteralPath $zipModeles).Length -lt 500000000) { Stop-Build "les modèles téléchargés sont incomplets : relancer (la connexion a dû être coupée)" }
    Write-Host "Décompression des modèles (une à deux minutes)..."
    Expand-Archive -LiteralPath $zipModeles -DestinationPath $tmp -Force
    New-Item -ItemType Directory -Force -Path $modeles | Out-Null
    Move-Item -Path (Join-Path $tmp "templates\*") -Destination $modeles -Force
    Remove-Item -Recurse -Force -LiteralPath $tmp
}

# --- numéro de version dans les préréglages d'export ---------------------------------------
$fichierPresets = Join-Path $racine "export_presets.cfg"
$presets = [System.IO.File]::ReadAllText($fichierPresets, [System.Text.Encoding]::UTF8)
$presets = $presets -replace '(?m)^application/file_version=.*$', "application/file_version=`"$version4`""
$presets = $presets -replace '(?m)^application/product_version=.*$', "application/product_version=`"$version4`""
$presets = $presets -replace '(?m)^application/short_version=.*$', "application/short_version=`"$version`""
$presets = $presets -replace '(?m)^application/version=.*$', "application/version=`"$version`""
[System.IO.File]::WriteAllText($fichierPresets, $presets, $sansBom)

function Add-Journal([string]$etape) {
    $chemin = Join-Path $racine "build\journal_godot.txt"
    if (Test-Path -LiteralPath $chemin) {
        Add-Content -Path $journalBuild -Value "===== $etape =====" -Encoding UTF8
        Add-Content -Path $journalBuild -Value (Get-Content -LiteralPath $chemin -Encoding UTF8) -Encoding UTF8
    }
}

Write-Host "Préparation du projet (import)..."
$code = Invoke-Godot $godot $racine @("--headless", "--path", ".", "--import") $journal
Add-Journal "import"
if ($code -ne 0) { Write-Host "   (l'import a renvoyé le code $code, voir le journal ; on continue)" -ForegroundColor Yellow }

if ($Test) {
    Write-Host "Test rapide (quelques minutes, la fenêtre reste muette)..."
    $env:GLAN_QUICK = "1"
    $code = Invoke-Godot $godot $racine @("--headless", "--path", ".", "res://tests/smoke_test.tscn") "build\journal_test.txt"
    Remove-Item Env:\GLAN_QUICK
    if ($code -ne 0) { Stop-Build "le test rapide a échoué (build\journal_test.txt) : rien n'est construit" }
    Write-Host "   test rapide réussi" -ForegroundColor Green
}

function Export-Plateforme([string]$preset, [string]$fichierRelatif, [long]$tailleMin) {
    $sortie = Join-Path $racine $fichierRelatif
    $dossier = Split-Path -Parent $sortie
    if (Test-Path -LiteralPath $dossier) { Remove-Item -Recurse -Force -LiteralPath $dossier }
    New-Item -ItemType Directory -Force -Path $dossier | Out-Null
    Write-Host "== Export $preset == (une à trois minutes, la fenêtre reste muette)"
    $code = Invoke-Godot $godot $racine @("--headless", "--path", ".", "--export-release", $preset, $fichierRelatif.Replace("\", "/")) $journal
    Add-Journal "export $preset"
    if ($code -ne 0) { Stop-Build "Godot a renvoyé le code $code pendant l'export $preset (voir build\journal_build.txt)" }
    if (-not (Test-Path -LiteralPath $sortie)) { Stop-Build "$fichierRelatif n'a pas été produit (voir build\journal_build.txt)" }
    if ((Get-Item -LiteralPath $sortie).Length -lt $tailleMin) { Stop-Build "$fichierRelatif est trop petit : export incomplet (voir build\journal_build.txt)" }
    $erreurs = Select-String -Path $journalBuild -Pattern "^(ERROR|SCRIPT ERROR)" | Where-Object { $_.Line -notmatch "shader cache" }
    if ($erreurs) { $erreurs | Select-Object -Last 3 | ForEach-Object { Write-Host $_.Line }; Stop-Build "Godot a signalé des erreurs pendant l'export $preset (voir build\journal_build.txt)" }
}

function New-LisezMoi([string]$plateforme, [string]$destination) {
    $texte = [System.IO.File]::ReadAllText((Join-Path $paquet "LISEZMOI_$plateforme.txt"), [System.Text.Encoding]::UTF8)
    $texte = $texte.Replace("{VERSION}", $version).Replace("`r`n", "`n")
    if ($plateforme -eq "windows") { [System.IO.File]::WriteAllText($destination, $texte.Replace("`n", "`r`n"), $avecBom) }
    else { [System.IO.File]::WriteAllText($destination, $texte, $sansBom) }
}

$archives = @()

if ($Quoi -eq "tout" -or $Quoi -eq "windows") {
    Export-Plateforme "Windows" "build\windows\$nom.exe" 30000000
    $exe = Join-Path $racine "build\windows\$nom.exe"
    if (-not (Test-ExeWindows $exe 30000000)) { Stop-Build "$nom.exe n'est pas un programme Windows valide" }
    if (-not (Test-Path -LiteralPath (Join-Path $racine "build\windows\$nom.pck"))) { Stop-Build "$nom.pck manquant" }
    $dossierPaquet = "$nom-$version-windows"
    $stage = Join-Path $build "stage_windows"
    if (Test-Path -LiteralPath $stage) { Remove-Item -Recurse -Force -LiteralPath $stage }
    $d = Join-Path $stage $dossierPaquet
    New-Item -ItemType Directory -Force -Path $d | Out-Null
    foreach ($f in @("$nom.exe", "$nom.console.exe", "$nom.pck")) { Copy-Item -LiteralPath (Join-Path $racine "build\windows\$f") -Destination $d }
    Copy-Item -LiteralPath (Join-Path $paquet "jouer_avec_journal.bat") -Destination $d
    New-LisezMoi "windows" (Join-Path $d "LISEZMOI.txt")
    $zip = Join-Path $build "$dossierPaquet.zip"
    if (Test-Path -LiteralPath $zip) { Remove-Item -Force -LiteralPath $zip }
    [System.IO.Compression.ZipFile]::CreateFromDirectory($d, $zip, [System.IO.Compression.CompressionLevel]::Optimal, $true)
    Remove-Item -Recurse -Force -LiteralPath $stage
    $archives += "$dossierPaquet.zip"
}

if ($Quoi -eq "tout" -or $Quoi -eq "macos") {
    Export-Plateforme "macOS" "build\macos\$nom.zip" 30000000
    $zip = Join-Path $build "$nom-$version-macos.zip"
    Copy-Item -LiteralPath (Join-Path $racine "build\macos\$nom.zip") -Destination $zip -Force
    $lm = Join-Path $racine "build\macos\LISEZMOI.txt"
    New-LisezMoi "macos" $lm
    $z = [System.IO.Compression.ZipFile]::Open($zip, [System.IO.Compression.ZipArchiveMode]::Update)
    try {
        $entree = $z.CreateEntry("LISEZMOI.txt")
        $flux = $entree.Open()
        try { $octets = [System.IO.File]::ReadAllBytes($lm); $flux.Write($octets, 0, $octets.Length) } finally { $flux.Dispose() }
    } finally { $z.Dispose() }
    $archives += "$nom-$version-macos.zip"
}

if ($Quoi -eq "tout" -or $Quoi -eq "linux") {
    Export-Plateforme "Linux" "build\linux\$nom.x86_64" 30000000
    if (-not (Test-Path -LiteralPath (Join-Path $racine "build\linux\$nom.pck"))) { Stop-Build "$nom.pck (Linux) manquant" }
    $dossierPaquet = "$nom-$version-linux"
    $stage = Join-Path $build "stage_linux"
    if (Test-Path -LiteralPath $stage) { Remove-Item -Recurse -Force -LiteralPath $stage }
    $d = Join-Path $stage $dossierPaquet
    New-Item -ItemType Directory -Force -Path $d | Out-Null
    foreach ($f in @("$nom.x86_64", "$nom.pck")) { Copy-Item -LiteralPath (Join-Path $racine "build\linux\$f") -Destination $d }
    Copy-Item -LiteralPath (Join-Path $racine "assets\icone.png") -Destination $d
    Copy-Item -LiteralPath (Join-Path $paquet "$nom.desktop") -Destination $d
    Copy-Item -LiteralPath (Join-Path $paquet "installer_raccourci.sh") -Destination $d
    New-LisezMoi "linux" (Join-Path $d "LISEZMOI.txt")
    $archive = Join-Path $build "$dossierPaquet.tar.gz"
    if (Test-Path -LiteralPath $archive) { Remove-Item -Force -LiteralPath $archive }
    if (Get-Command tar.exe -ErrorAction SilentlyContinue) {
        & tar.exe -C $stage -czf $archive $dossierPaquet
        if ($LASTEXITCODE -ne 0) { Stop-Build "l'archive Linux n'a pas pu être créée" }
    } else { Stop-Build "tar.exe introuvable (Windows 10 version 1803 ou plus récent requis pour l'archive Linux)" }
    Remove-Item -Recurse -Force -LiteralPath $stage
    $archives += "$dossierPaquet.tar.gz"
    Write-Host "   (attention : construite sous Windows, l'archive Linux perd le droit d'exécution du fichier ; le LISEZMOI donne la commande chmod +x. Pour une version à publier, utiliser ./release.sh sur Mac ou Linux.)" -ForegroundColor Yellow
}

# --- sommes de contrôle et résumé ------------------------------------------------------------
$lignes = @()
foreach ($a in $archives) {
    $chemin = Join-Path $build $a
    if (-not (Test-Path -LiteralPath $chemin) -or (Get-Item -LiteralPath $chemin).Length -eq 0) { Stop-Build "$a est absent ou vide" }
    $lignes += ((Get-FileHash -Algorithm SHA256 -LiteralPath $chemin).Hash.ToLower() + "  " + $a)
}
[System.IO.File]::WriteAllText((Join-Path $build "SHA256SUMS.txt"), (($lignes -join "`n") + "`n"), $sansBom)
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " Version $version construite. Archives à envoyer (dossier build\) :" -ForegroundColor Green
foreach ($a in $archives) {
    $mo = [math]::Round((Get-Item -LiteralPath (Join-Path $build $a)).Length / 1MB, 1)
    Write-Host ("   {0,-50} {1} Mo" -f $a, $mo)
}
Write-Host " Sommes SHA-256 : build\SHA256SUMS.txt" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
