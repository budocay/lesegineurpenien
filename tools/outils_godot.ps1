# Fonctions communes aux scripts Windows (construction et installation).
# Chargé par « . outils_godot.ps1 » ; ne se lance pas seul.

# Vrai si le fichier est un programme Windows 64 bits complet (signature MZ puis PE, machine x64 ou ARM64).
# Un téléchargement coupé, un antivirus qui met le fichier en quarantaine ou un mauvais zip donnent un fichier
# que Windows refuse avec « CreateProcess failed, error 193 » (programme non valide).
function Test-ExeWindows {
    param([string]$Chemin, [long]$TailleMin = 40000000)
    if (-not (Test-Path -LiteralPath $Chemin)) { return $false }
    $fichier = Get-Item -LiteralPath $Chemin
    if ($fichier.Length -lt $TailleMin) { return $false }
    try {
        $flux = [System.IO.File]::OpenRead($fichier.FullName)
        try {
            $tete = New-Object byte[] 64
            if ($flux.Read($tete, 0, 64) -lt 64) { return $false }
            if ($tete[0] -ne 0x4D -or $tete[1] -ne 0x5A) { return $false }          # « MZ »
            $posPE = [BitConverter]::ToInt32($tete, 60)
            if ($posPE -lt 64 -or $posPE -gt 4096) { return $false }
            [void]$flux.Seek($posPE, [System.IO.SeekOrigin]::Begin)
            $pe = New-Object byte[] 6
            if ($flux.Read($pe, 0, 6) -lt 6) { return $false }
            if ($pe[0] -ne 0x50 -or $pe[1] -ne 0x45 -or $pe[2] -ne 0 -or $pe[3] -ne 0) { return $false }   # « PE\0\0 »
            $machine = [BitConverter]::ToUInt16($pe, 4)
            return ($machine -eq 0x8664 -or $machine -eq 0xAA64)
        } finally { $flux.Dispose() }
    } catch { return $false }
}

# Numéro de version du jeu, lu dans project.godot (application/config/version).
function Get-VersionJeu {
    param([string]$Racine)
    $texte = [System.IO.File]::ReadAllText((Join-Path $Racine "project.godot"), [System.Text.Encoding]::UTF8)
    $m = [regex]::Match($texte, '(?m)^config/version="(\d+\.\d+\.\d+)"')
    if (-not $m.Success) { throw "application/config/version (trois nombres, par exemple 0.6.0) introuvable dans project.godot" }
    return $m.Groups[1].Value
}

# Lance Godot et attend sa fin. Les arguments ne contiennent jamais d'espace : le dossier du jeu est donné par
# -WorkingDirectory, les chemins sont relatifs. Le programme lui-même est passé à part, Start-Process le protège.
# Renvoie le code de sortie. Le journal de Godot est écrit par Godot lui-même (--log-file).
function Invoke-Godot {
    param([string]$Godot, [string]$Racine, [string[]]$Arguments, [string]$Journal)
    $liste = @($Arguments) + @("--log-file", $Journal)
    $p = Start-Process -FilePath $Godot -ArgumentList ($liste -join " ") -WorkingDirectory $Racine -Wait -PassThru -NoNewWindow
    return $p.ExitCode
}

# Télécharge une adresse avec barre de progression (curl.exe, fourni avec Windows 10 et 11) ou en silence.
function Get-Telechargement {
    param([string]$Url, [string]$Fichier)
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -L --fail --progress-bar -o $Fichier $Url
        if ($LASTEXITCODE -ne 0) { throw "Le téléchargement a échoué (code $LASTEXITCODE) : $Url" }
    } else {
        Write-Host "(pas de barre de progression sur cette machine : patienter, la fenêtre ne bouge pas)"
        Invoke-WebRequest -Uri $Url -OutFile $Fichier -UseBasicParsing
    }
}
