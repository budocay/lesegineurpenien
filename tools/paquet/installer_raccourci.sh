#!/bin/sh
# Crée le raccourci du jeu dans le menu des applications (session courante seulement).
ici="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$HOME/.local/share/applications" "$HOME/.local/share/icons"
cp "$ici/icone.png" "$HOME/.local/share/icons/SeigneurDesAnneauxPeniens.png"
cat > "$HOME/.local/share/applications/SeigneurDesAnneauxPeniens.desktop" <<FIN
[Desktop Entry]
Type=Application
Name=Le Seigneur des Anneaux Péniens
Comment=RPG parodique HD-2D
Exec=$ici/SeigneurDesAnneauxPeniens.x86_64
Path=$ici
Icon=SeigneurDesAnneauxPeniens
Terminal=false
Categories=Game;RolePlaying;
FIN
echo "Raccourci créé. Le jeu apparaît dans le menu des applications."
