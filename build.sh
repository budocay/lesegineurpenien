#!/bin/bash
# Construit le jeu en version finale pour Windows, macOS et Linux, dans le dossier build/.
#   ./build.sh            les trois plateformes
#   ./build.sh windows    une seule (windows, macos ou linux)
# Au premier lancement, télécharge les modèles d'export de Godot 4.7.2 (1,2 Go, une seule fois).
set -e
cd "$(dirname "$0")"
VERSION="4.7.2"
case "$(uname -s)" in
  Darwin) GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
          TEMPLATES="$HOME/Library/Application Support/Godot/export_templates/$VERSION.stable" ;;
  *)      GODOT="${GODOT:-godot}"
          TEMPLATES="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$VERSION.stable" ;;
esac
if ! command -v "$GODOT" >/dev/null 2>&1 && [ ! -x "$GODOT" ]; then
  echo "Godot introuvable ($GODOT). Indiquer son chemin : GODOT=/chemin/vers/godot ./build.sh"; exit 1
fi
if [ ! -f "$TEMPLATES/version.txt" ]; then
  echo "Téléchargement des modèles d'export de Godot $VERSION (1,2 Go)..."
  TMP="$(mktemp -d)"
  curl -L --fail -sS -o "$TMP/modeles.tpz" \
    "https://github.com/godotengine/godot/releases/download/$VERSION-stable/Godot_v$VERSION-stable_export_templates.tpz"
  unzip -q "$TMP/modeles.tpz" -d "$TMP"
  mkdir -p "$TEMPLATES"
  mv "$TMP/templates/"* "$TEMPLATES/"
  rm -rf "$TMP"
fi
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
build() { # nom du préréglage, fichier produit
  mkdir -p "$(dirname "$2")"
  echo "== $1 =="
  "$GODOT" --headless --path . --export-release "$1" "$2" 2>&1 | grep -iE "error|erreur|savepack.*100|^\[ DONE" || true
  if [ -s "$2" ]; then echo "   fait : $2 ($(du -h "$2" | cut -f1))"; else echo "   ÉCHEC : $2 n'a pas été produit"; FAILED=1; fi
}
WHAT="${1:-tout}"
[ "$WHAT" = tout ] || [ "$WHAT" = windows ] && build "Windows" "build/windows/SeigneurDesAnneauxPeniens.exe"
[ "$WHAT" = tout ] || [ "$WHAT" = macos ]   && build "macOS"   "build/macos/SeigneurDesAnneauxPeniens.zip"
[ "$WHAT" = tout ] || [ "$WHAT" = linux ]   && build "Linux"   "build/linux/SeigneurDesAnneauxPeniens.x86_64"
[ -z "$FAILED" ] && echo "Terminé : voir le dossier build/" || exit 1
