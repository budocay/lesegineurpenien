#!/bin/bash
# Lance le jeu sur Mac dans sa propre fenêtre (double-cliquer sur ce fichier).
# À la manette, préférer ce lancement à F5 dans l'éditeur Godot : sur Mac, une manette ne
# parle qu'à l'application au premier plan, et un jeu lancé dans la fenêtre intégrée de
# l'éditeur ne reçoit alors aucun bouton.
cd "$(dirname "$0")"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [ ! -x "$GODOT" ]; then
  echo "Godot introuvable ($GODOT). L'installer dans Applications, ou indiquer son chemin : GODOT=/chemin ./jouer.command"
  read -r -p "Appuyer sur Entrée pour fermer."
  exit 1
fi
exec "$GODOT" --path .
