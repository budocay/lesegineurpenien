#!/bin/bash
# Prépare une version : ./release.sh 0.7.0
# Met à jour le numéro de version (project.godot, un seul endroit), construit et teste, crée le commit
# et le tag v0.7.0. Ne pousse rien : la commande à copier est affichée à la fin.
set -eu
cd "$(dirname "$0")"
NOUVELLE="${1:-}"
case "$NOUVELLE" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) echo "Usage : ./release.sh 0.7.0   (trois nombres séparés par des points)"; exit 2 ;;
esac
case "$NOUVELLE" in *[!0-9.]*) echo "Version invalide : $NOUVELLE"; exit 2 ;; esac
ACTUELLE="$(sed -n 's/^config\/version="\(.*\)"$/\1/p' project.godot | head -1)"
TAG="v$NOUVELLE"
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then echo "Le tag $TAG existe déjà."; exit 1; fi
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Des modifications ne sont pas enregistrées (git status). Les enregistrer d'abord, puis relancer."; exit 1
fi
BRANCHE="$(git rev-parse --abbrev-ref HEAD)"
echo "Version $ACTUELLE -> $NOUVELLE (branche $BRANCHE)"

sed -i.bak "s/^config\/version=.*/config\/version=\"$NOUVELLE\"/" project.godot && rm -f project.godot.bak
if ! ./build.sh tout --test; then
  git checkout -- project.godot export_presets.cfg
  echo "La construction a échoué : le numéro de version est remis comme avant, rien n'est enregistré."
  exit 1
fi

git add project.godot export_presets.cfg
git commit -q -m "🔖 Version $NOUVELLE

Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>"
git tag -a "$TAG" -m "Le Seigneur des Anneaux Péniens $NOUVELLE"
echo
echo "Version $NOUVELLE prête : commit et tag $TAG créés (rien n'est encore envoyé)."
echo "Archives d'essai : build/  (SHA256SUMS.txt à côté)"
echo "Pour publier sur GitHub (le serveur reconstruit et publie la release) :"
echo "    git push origin $BRANCHE $TAG"
