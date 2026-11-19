#!/bin/bash
# Construit le jeu en version finale (Windows, macOS, Linux) et prépare les archives à envoyer.
#
#   ./build.sh                  les trois plateformes
#   ./build.sh windows          une seule (windows, macos ou linux)
#   ./build.sh tout --test      lance d'abord le test rapide et refuse de construire s'il échoue
#
# Résultat dans build/ :
#   SeigneurDesAnneauxPeniens-<version>-windows.zip, -macos.zip, -linux.tar.gz, SHA256SUMS.txt
#   journal_build.txt (tout ce que Godot a dit), build/<plateforme>/ (fichiers avant archivage)
# La version se lit dans project.godot (application/config/version) : un seul endroit.
# Au premier lancement, télécharge les modèles d'export de Godot (1,2 Go, une seule fois).
set -u
cd "$(dirname "$0")"
RACINE="$PWD"
GODOT_VERSION="${GODOT_VERSION:-4.7.2}"
NOM="SeigneurDesAnneauxPeniens"
PAQUET="tools/paquet"
WHAT="tout"
TEST=0
for a in "$@"; do
  case "$a" in
    --test) TEST=1 ;;
    windows|macos|linux|tout) WHAT="$a" ;;
    *) echo "Argument inconnu : $a (attendu : windows, macos, linux, tout, --test)"; exit 2 ;;
  esac
done

echec() { echo "ERREUR : $*" >&2; exit 1; }

# --- version ---------------------------------------------------------------
VERSION="$(sed -n 's/^config\/version="\(.*\)"$/\1/p' project.godot | head -1)"
[ -n "$VERSION" ] || echec "application/config/version introuvable dans project.godot"
case "$VERSION" in *[!0-9.]*|"") echec "numéro de version invalide : $VERSION (attendu : 1.2.3)" ;; esac
VERSION4="$VERSION.0"   # Windows veut quatre nombres (0.6.0 -> 0.6.0.0)
[ "$(echo "$VERSION" | tr -cd . | wc -c | tr -d ' ')" = 2 ] || echec "la version doit avoir trois nombres (0.6.0), pas $VERSION"

# --- Godot et modèles d'export ----------------------------------------------
case "$(uname -s)" in
  Darwin) GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
          TEMPLATES="$HOME/Library/Application Support/Godot/export_templates/$GODOT_VERSION.stable" ;;
  *)      GODOT="${GODOT:-godot}"
          TEMPLATES="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$GODOT_VERSION.stable" ;;
esac
if ! command -v "$GODOT" >/dev/null 2>&1 && [ ! -x "$GODOT" ]; then
  echec "Godot introuvable ($GODOT). Indiquer son chemin : GODOT=/chemin/vers/godot ./build.sh"
fi
VU="$("$GODOT" --version 2>/dev/null | head -1)"
case "$VU" in
  "$GODOT_VERSION".stable*) ;;
  *) echec "Godot $GODOT_VERSION est requis, mais « $VU » a été trouvé. Les modèles d'export doivent avoir exactement la même version que le programme." ;;
esac
if [ ! -f "$TEMPLATES/version.txt" ]; then
  echo "Téléchargement des modèles d'export de Godot $GODOT_VERSION (1,2 Go, une seule fois)..."
  TMP="$(mktemp -d)"
  curl -L --fail -sS -o "$TMP/modeles.tpz" \
    "https://github.com/godotengine/godot/releases/download/$GODOT_VERSION-stable/Godot_v$GODOT_VERSION-stable_export_templates.tpz" \
    || echec "téléchargement des modèles impossible"
  unzip -q "$TMP/modeles.tpz" -d "$TMP" || echec "modèles illisibles (téléchargement incomplet ?)"
  mkdir -p "$TEMPLATES"
  mv "$TMP/templates/"* "$TEMPLATES/"
  rm -rf "$TMP"
fi

# --- numéro de version dans les préréglages d'export ---------------------------
# (les préréglages ne lisent pas project.godot : on y recopie la version, sans rien changer d'autre)
sed -i.bak \
  -e "s/^application\/file_version=.*/application\/file_version=\"$VERSION4\"/" \
  -e "s/^application\/product_version=.*/application\/product_version=\"$VERSION4\"/" \
  -e "s/^application\/short_version=.*/application\/short_version=\"$VERSION\"/" \
  -e "s/^application\/version=.*/application\/version=\"$VERSION\"/" \
  export_presets.cfg && rm -f export_presets.cfg.bak

mkdir -p build
JOURNAL="build/journal_build.txt"
: > "$JOURNAL"
echo "Le Seigneur des Anneaux Péniens - construction de la version $VERSION"
echo "(journal complet : $JOURNAL)"

echo "== Préparation du projet (import) =="
"$GODOT" --headless --path . --import >>"$JOURNAL" 2>&1 || echo "   (l'import a renvoyé un code d'erreur, voir le journal ; on continue)"

if [ "$TEST" = 1 ]; then
  echo "== Test rapide (quelques minutes) =="
  if GLAN_QUICK=1 "$GODOT" --headless --path . res://tests/smoke_test.tscn >build/journal_test.txt 2>&1; then
    echo "   test rapide réussi"
  else
    tail -15 build/journal_test.txt
    echec "le test rapide a échoué (build/journal_test.txt) : rien n'est construit"
  fi
fi

# --- outils --------------------------------------------------------------------
sha256() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$@"; else shasum -a 256 "$@"; fi; }
taille() { wc -c < "$1" | tr -d ' '; }
lisez_moi() { # plateforme, fichier de sortie
  { [ "$1" = windows ] && printf '\xef\xbb\xbf'; sed "s/{VERSION}/$VERSION/g" "$PAQUET/LISEZMOI_$1.txt"; } > "$2.tmp"
  if [ "$1" = windows ]; then sed 's/$/\r/' "$2.tmp" > "$2"; else mv "$2.tmp" "$2"; fi
  rm -f "$2.tmp"
}
exporter() { # préréglage, fichier produit, taille minimale en octets
  echo "== Export $1 (une à trois minutes) =="
  mkdir -p "$(dirname "$2")"
  "$GODOT" --headless --path . --export-release "$1" "$RACINE/$2" >>"$JOURNAL" 2>&1
  [ -s "$2" ] || echec "$2 n'a pas été produit (voir $JOURNAL)"
  [ "$(taille "$2")" -ge "$3" ] || echec "$2 est trop petit ($(taille "$2") octets) : export incomplet (voir $JOURNAL)"
  if grep -aE "^(ERROR|SCRIPT ERROR)" "$JOURNAL" | grep -v "shader cache" | tail -3 | grep . ; then
    echec "Godot a signalé des erreurs pendant l'export $1 (voir $JOURNAL)"
  fi
}
RESUME=()
FINI=()

# --- Windows -------------------------------------------------------------------
construire_windows() {
  rm -rf build/windows build/stage_windows
  exporter "Windows" "build/windows/$NOM.exe" 30000000
  [ -s "build/windows/$NOM.pck" ] && [ "$(taille "build/windows/$NOM.pck")" -ge 1000000 ] || echec "$NOM.pck manquant ou trop petit"
  [ -s "build/windows/$NOM.console.exe" ] || echec "$NOM.console.exe manquant"
  [ "$(head -c 2 "build/windows/$NOM.exe")" = "MZ" ] || echec "$NOM.exe n'est pas un programme Windows valide"
  local d="build/stage_windows/$NOM-$VERSION-windows"
  mkdir -p "$d"
  cp "build/windows/$NOM.exe" "build/windows/$NOM.console.exe" "build/windows/$NOM.pck" "$d/"
  cp "$PAQUET/jouer_avec_journal.bat" "$d/"
  lisez_moi windows "$d/LISEZMOI.txt"
  rm -f "build/$NOM-$VERSION-windows.zip"
  (cd build/stage_windows && zip -qr -X "../$NOM-$VERSION-windows.zip" "$NOM-$VERSION-windows") || echec "zip Windows impossible"
  rm -rf build/stage_windows
  FINI+=("$NOM-$VERSION-windows.zip")
}

# --- macOS ---------------------------------------------------------------------
construire_macos() {
  rm -rf build/macos
  exporter "macOS" "build/macos/$NOM.zip" 30000000
  local z="build/$NOM-$VERSION-macos.zip"
  cp "build/macos/$NOM.zip" "$z"
  lisez_moi macos "build/macos/LISEZMOI.txt"
  (cd build/macos && zip -q -X "../$NOM-$VERSION-macos.zip" LISEZMOI.txt) || echec "zip macOS impossible"
  FINI+=("$NOM-$VERSION-macos.zip")
}

# --- Linux ---------------------------------------------------------------------
construire_linux() {
  rm -rf build/linux build/stage_linux
  exporter "Linux" "build/linux/$NOM.x86_64" 30000000
  [ -s "build/linux/$NOM.pck" ] && [ "$(taille "build/linux/$NOM.pck")" -ge 1000000 ] || echec "$NOM.pck manquant ou trop petit"
  local d="build/stage_linux/$NOM-$VERSION-linux"
  mkdir -p "$d"
  cp "build/linux/$NOM.x86_64" "build/linux/$NOM.pck" "$d/"
  chmod +x "$d/$NOM.x86_64"
  cp assets/icone.png "$d/icone.png"
  cp "$PAQUET/$NOM.desktop" "$PAQUET/installer_raccourci.sh" "$d/"
  chmod +x "$d/installer_raccourci.sh"
  lisez_moi linux "$d/LISEZMOI.txt"
  rm -f "build/$NOM-$VERSION-linux.tar.gz"
  COPYFILE_DISABLE=1 tar -C build/stage_linux -czf "build/$NOM-$VERSION-linux.tar.gz" "$NOM-$VERSION-linux" || echec "archive Linux impossible"
  rm -rf build/stage_linux
  FINI+=("$NOM-$VERSION-linux.tar.gz")
}

[ "$WHAT" = tout ] || [ "$WHAT" = windows ] && construire_windows
[ "$WHAT" = tout ] || [ "$WHAT" = macos ]   && construire_macos
[ "$WHAT" = tout ] || [ "$WHAT" = linux ]   && construire_linux

# --- sommes de contrôle et résumé ----------------------------------------------
(cd build && sha256 "${FINI[@]}" > SHA256SUMS.txt)
echo
echo "=========================================================="
echo " Version $VERSION construite. Archives à envoyer (dossier build/) :"
for f in "${FINI[@]}"; do
  [ -s "build/$f" ] || echec "$f est absent ou vide"
  printf '   %-50s %s\n' "$f" "$(du -h "build/$f" | cut -f1)"
done
echo " Sommes SHA-256 : build/SHA256SUMS.txt"
echo "=========================================================="
