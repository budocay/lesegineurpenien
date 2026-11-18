# Glandoulf le Gris — consignes pour Claude

RPG parodique HD-2D sous Godot 4.7 (Forward+, macOS), construit session après session.
L'auteur n'est pas développeur : il appuie sur F5, joue, et dit ce qu'il en pense.

## À lire en début de session

1. `docs/SUIVI.md` : état du jeu, décisions numérotées avec leur raison, limites connues.
2. `docs/HISTOIRE.md` : bible de l'histoire (référence ; les inventions vont dans « Ajouts »).
3. `brief.txt` : cahier des charges d'origine. `docs/FORMAT_DONNEES.md` : format des données.

## Règles qui ne se discutent pas

- **F5 doit lancer le jeu sans erreur.** Une erreur bloque complètement l'auteur.
- **Rien dans l'éditeur Godot.** Tout passe par des fichiers texte : scripts GDScript,
  `project.godot`, JSON de `data/`. Les scènes se construisent par code.
- **Moteur et contenu séparés.** Cartes, dialogues, quêtes, personnages, ennemis,
  compétences, objets, talents : dans `data/`. Ajouter du contenu ne doit pas demander de code.
- **Pas de `class_name`** : les scripts se chargent par `preload` de leur chemin.
- **Sprites : un seul point d'accès**, `src/gfx/sprite_library.gd` (autoload `Sprites`). Il
  charge un PNG de `assets/sprites/` s'il existe, sinon la version peinte par code.
- **Textes du jeu en français.** Ton : personnages sérieux dans une situation ridicule,
  double sens, jamais de vulgarité explicite (voir la règle de ton de la bible).
- **Noms définitifs** : Sam Gamelle, Fripon Besace, Pépine Bontabac, Aragrogne, Légolasse,
  Gimlette. Identifiants : `sam`, `fripon`, `pepine`, `aragrogne`, `legolasse`, `gimlette`.
  Ne jamais réintroduire les anciennes variantes.
- **Décider seul et noter.** Chaque décision va dans `docs/SUIVI.md` avec sa raison. Ne
  poser une question que si un mauvais choix serait long à défaire.
- **Commits en français avec emoji.** Une étape à la fois, un commit par étape.

## Vérifier (obligatoire à la fin de chaque étape)

```bash
# test complet, sans fenêtre, environ cinq minutes : doit finir par « RESULTAT : OK »
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/smoke_test.tscn
# passage rapide (règles, équilibre, talents), quelques secondes
GLAN_QUICK=1 /Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/smoke_test.tscn
# captures d'écran (ouvre une fenêtre deux à trois minutes, ne pas toucher au clavier)
/Applications/Godot.app/Contents/MacOS/Godot --path . res://tests/capture.tscn -- "$PWD/docs/captures"
```

Chaque étape étend `tests/smoke_test.gd`, refait les captures, met à jour `docs/SUIVI.md`
et ce fichier, puis se termine par un compte rendu complet en français : ce qui a été
construit, comment l'essayer en jouant, ce qui n'a pas pu être vérifié.

## Où est quoi

- `src/core/` : commandes, base de données (`Database`), état de la partie (`GameState`),
  sauvegarde, sons générés.
- `src/gfx/` : peinture des sprites et textures par code, `sprite_library.gd`.
- `src/world/` : construction des cartes, joueur, personnages, caméra, ambiance.
- `src/battle/` : `battle_engine.gd` (toutes les règles, sans affichage : c'est lui que
  les tests interrogent), `battle_scene.gd` (arène et mise en scène), `battle_actor.gd`
  (poses d'un combattant), `battle_fx.gd` (joue les animations de `data/animations.json`),
  `battle_ui.gd`, `rules.gd` (niveaux, statistiques, talents).
- Animations de combat : une entrée de `data/animations.json` par compétence, objet et
  attaque de base (même identifiant ; `attack_anim` pour les attaques). Sprites d'effets
  dans `src/gfx/fx_painter.gd` (accès : `Sprites.fx`), sons dans `src/core/sfx.gd`.
  Format complet dans `docs/FORMAT_DONNEES.md`.
- `src/ui/` : titre, dialogues, pause, HUD, `game_menu.gd` (équipe, inventaire, journal,
  boutiques), `talent_screen.gd` (écran de talents).
- `tests/` : `smoke_test` (test automatique) et `capture` (captures d'écran).

## État au 18 novembre 2026

Chapitre 1 jouable de bout en bout (étapes 1 à 5). Talents terminés avec un écran dédié.
Animations de combat terminées (107 animations décrites dans les données). Ordre de travail fixé par l'auteur pour la suite, une étape à la fois, en
s'arrêtant après chacune pour qu'il teste :

1. ~~Talents~~ (fait).
2. ~~Animations de combat~~ (fait ; les poses sont des mouvements du sprite entier, à
   remplacer par de vrais dessins pendant l'étape pixel art).
3. **Pixel art** : sprites refaits (quatre poses de marche par direction, repos animé),
   sprites dédiés pour les Morfales et le Naze, monstres retravaillés, portraits dans les
   dialogues et les menus, décors plus riches ; comparer les captures avant/après.

## Pièges connus

- Un sprite d'effet translucide est flouté par le flou de profondeur : garder la découpe
  franche (`ALPHA_SCISSOR`) de `battle_fx.gd`.
- L'écran tourne à 120 images par seconde : dans `tests/capture.gd`, attendre en secondes
  et non en images quand l'instant compte.
- Toute nouvelle compétence, tout nouvel objet de combat ou ennemi doit avoir son entrée
  dans `data/animations.json`, sinon le test automatique échoue.

- L'agent principal n'a pas toujours d'outil pour afficher les PNG : faire décrire les
  captures par un agent secondaire et le dire dans le compte rendu.
- Le test complet affiche « ObjectDB instances leaked » à la fermeture : sans effet.
- Les combats simulés jouent mal les talents (ni provocation ni sorts de zone) : ils
  sous-estiment la force réelle de l'équipe.
