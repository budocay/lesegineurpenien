# Faire une version et la donner à des amis

## Faire une version (sur le Mac)

1. Enregistrer le travail (`git status` ne doit rien montrer de modifié).
2. `./release.sh 0.7.0` (le numéro voulu, trois nombres).
   Le script change le numéro de version, lance le test rapide, construit les trois jeux,
   fait un commit « 🔖 Version 0.7.0 » et le tag `v0.7.0`. Il ne pousse rien.
3. Il affiche la commande finale : `git push origin main v0.7.0`. La copier.
   Quand le tag arrive sur GitHub, le serveur refait la construction et publie la release
   (onglet « Releases » du dépôt), avec les trois archives et les sommes SHA-256.
4. Envoyer aux amis le lien de la release, ou les fichiers du dossier `build/`.

Le numéro de version vit à un seul endroit : `application/config/version` dans `project.godot`.
Il est repris dans les propriétés de l'exe Windows, dans l'app macOS, dans le nom des archives,
et affiché en bas à droite de l'écran-titre.

Sans publier : `./build.sh` (ou `build.bat` sous Windows) construit seulement dans `build/`.
`./build.sh windows` ne fait qu'une plateforme ; `--test` lance d'abord le test rapide et
refuse de construire s'il échoue. Tout ce que Godot dit est dans `build/journal_build.txt`.
Le dossier `build/` n'est pas enregistré dans git.

## Ce qui est produit (dossier `build/`)

| Fichier | Contenu |
|---|---|
| `SeigneurDesAnneauxPeniens-<version>-windows.zip` | l'exe, le `.pck` (données du jeu), la variante `.console.exe`, `jouer_avec_journal.bat`, `LISEZMOI.txt` |
| `SeigneurDesAnneauxPeniens-<version>-macos.zip` | l'app « Le Seigneur des Anneaux Péniens.app » (Intel et Apple Silicon) et `LISEZMOI.txt` |
| `SeigneurDesAnneauxPeniens-<version>-linux.tar.gz` | le programme, le `.pck`, l'icône, le raccourci `.desktop`, `LISEZMOI.txt` |
| `SHA256SUMS.txt` | les empreintes, pour vérifier qu'un fichier n'a pas été abîmé |

Le paquet ne contient que le jeu : pas de `tests/`, `docs/`, `tools/`, pas de notes `.md` ni
`.txt`, et jamais le dossier `assets/music/` (musiques personnelles). Les fichiers de `data/`
y sont. Les modèles (`.pck`) sont à côté de l'exe Windows et Linux (et dans l'app sur Mac).

## Installer chez un ami

**Windows.** Extraire le zip (ne pas lancer depuis le zip), double-cliquer sur
`SeigneurDesAnneauxPeniens.exe`. Windows SmartScreen dit « Windows a protégé votre
ordinateur » : cliquer « Informations complémentaires » puis « Exécuter quand même ». Cela
vient de l'absence de signature payante, pas d'un problème du jeu. Un antivirus qui hésite :
c'est pour cela que l'exe et le `.pck` sont séparés (un exe qui contient ses données
déclenche plus souvent de fausses alertes).

**macOS.** Ouvrir le zip, mettre l'app dans Applications. Premier lancement : clic droit sur
l'app, « Ouvrir », « Ouvrir » (macOS récent : double-clic, puis Réglages Système >
Confidentialité et sécurité > « Ouvrir quand même »). Si macOS dit « endommagée » :
`xattr -cr "/Applications/Le Seigneur des Anneaux Péniens.app"` dans le Terminal. L'app est
signée « ad hoc » (sans compte développeur Apple), donc non notarisée : c'est normal.

**Linux.** `tar xzf …tar.gz`, puis `./SeigneurDesAnneauxPeniens.x86_64` (au besoin
`chmod +x`). `./installer_raccourci.sh` ajoute le jeu au menu des applications.

## Sauvegardes et journaux

Le jeu écrit tout dans un dossier « utilisateur » (Godot l'appelle `user://`) :

| Système | Dossier |
|---|---|
| Windows | `%APPDATA%\Godot\app_userdata\Le Seigneur des Anneaux Péniens` |
| macOS | `~/Library/Application Support/Godot/app_userdata/Le Seigneur des Anneaux Péniens` |
| Linux | `~/.local/share/godot/app_userdata/Le Seigneur des Anneaux Péniens` |

Dedans : les sauvegardes, `settings.cfg` (réglages), des caches de sprites, et
`logs/godot.log` (le journal du jeu, les cinq derniers sont gardés). Un ami qui a un problème
envoie ce `godot.log`. Sous Windows, `jouer_avec_journal.bat` écrit en plus `journal.txt`
à côté du jeu. Changer d'ordinateur : copier ce dossier.

## Réglages d'export retenus (et pourquoi)

Documentation Godot 4.7 : exporting_projects, exporting_for_windows, exporting_for_macos,
et les pages de référence `EditorExportPlatformWindows`, `…MacOS`, `…LinuxBSD`
(https://docs.godotengine.org/en/4.7/tutorials/export/). Tout est dans `export_presets.cfg`
et `project.godot`.

- Windows : `binary_format/embed_pck=false` (exe et `.pck` séparés : moins de fausses alertes
  d'antivirus) ; `binary_format/architecture="x86_64"` ; `application/modify_resources=true` avec
  `application/icon`, `product_name`, `company_name`, `file_description`, `file_version`,
  `product_version`, `copyright` : Godot 4.7 écrit lui-même l'icône et les métadonnées dans
  l'exe, `rcedit` n'est plus nécessaire ; `debug/export_console_wrapper=2` (fournit le
  `.console.exe`) ; `codesign/enable=false`.
- macOS : `binary_format/architecture="universal"` ; `application/bundle_identifier`,
  `application/short_version`, `application/version`, `application/app_category`
  (`public.app-category.role-playing-games`) ; `codesign/codesign=1` (ad hoc intégré),
  `notarization/notarization=0`. `NSHighResolutionCapable` est ajouté par Godot ; aucune clé
  d'usage pour les manettes n'est demandée (hors bac à sable).
- Linux : `binary_format/architecture="x86_64"`, `embed_pck=false`.
- Contenu : `export_filter="all_resources"`, `include_filter="data/*"`, `exclude_filter` retire
  `tests/ docs/ tools/ build/ .github/ assets/music/` et les `*.md *.txt *.bat *.sh *.ps1 *.py` ;
  `script_export_mode=2` (scripts en jetons binaires compressés : plus petit, plus rapide à lire).
- Projet : `application/config/version`, `application/boot_splash/image`, `bg_color`,
  `use_filter` (écran de démarrage aux couleurs du jeu), `application/config/icon`,
  `debug/file_logging/enable_file_logging` et `max_log_files`. Aucun réglage de rendu modifié.

L'icône et l'écran de démarrage (`assets/icone.png`, `assets/demarrage.png`) sont peints par
`python3 tools/fabriquer_images.py` ; relancer ce script seulement pour les changer.

## Si le build Windows échoue avec « CreateProcess failed, error 193 »

Windows répond 193 quand on lui demande de lancer un fichier qui n'est pas un programme
valide : un Godot téléchargé à moitié, abîmé par l'antivirus, ou une variante « console » qui
relance le vrai programme par un chemin mal compris (dossier avec espaces ou accents).
`build.bat` vérifie maintenant le fichier avant de s'en servir (signature, taille,
architecture), le retélécharge s'il est mauvais, ne passe que des chemins sans espace à Godot
et écrit tout dans `build\journal_build.txt`. Si l'erreur revient, supprimer le dossier
`tools\godot` et relancer `installer_windows.bat`.
