# Le Seigneur des Anneaux Péniens — consignes pour Claude

Titre du jeu : « Le Seigneur des Anneaux Péniens » (décision 124 ; « Glandoulf le Gris » est
le héros et l'ancien titre de travail, le dossier garde ce nom). Le jeu doit en jouer partout :
sous-entendus, noms de créatures, de lieux et d'objets à double sens, sans jamais un mot cru.

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
- **Noms définitifs** (liste de l'auteur du 18 novembre 2026, décision 105) : Glandoulf,
  Sam Gamelle, Froton Salfait, Pépin Bontabac (un homme), Merri Brandemou (son cousin),
  Aragrogne, Digoulasse, Grimli, Isidur, Bromure du Gouda. Identifiants : `glandoulf`, `sam`,
  `froton`, `pepin`, `merri`, `aragrogne`, `digoulasse`, `grimli`. Ne jamais réintroduire
  les anciennes variantes : Fripon, Besace, Pépine, Légolasse, Gimlette (elles ne survivent
  que dans l'historique de `docs/SUIVI.md` et dans `GameState.migrate_old_ids`, qui convertit
  les anciennes sauvegardes).
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
  sauvegarde, sons générés (`sfx.gd`), musique générée (`music.gd`).
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
Animations de combat terminées (107 animations décrites dans les données). Pixel art
terminé. Les trois priorités fixées par l'auteur sont faites :

1. ~~Talents~~ (fait).
2. ~~Animations de combat~~ (fait ; les poses sont des mouvements du sprite entier, à
   remplacer par de vrais dessins pendant l'étape pixel art).
3. ~~Pixel art~~ (fait : planches de 11 poses par direction, `species` pour Morfales et
   Naze, monstres à quatre poses, portraits peints, décors enrichis ; captures d'avant
   dans `docs/captures/avant_pixel_art/`).

Chapitre 2 (Brie) jouable. Noms définitifs appliqués et Merri Brandemou intégré (il rejoint
l'équipe à l'arrivée à Brie ; fiche dans la bible, décisions 105 à 110 du suivi).

Histoire reprise à la demande de l'auteur : Isidur garde l'anneau (prologue réécrit),
Glandoulf a laissé faire puis menti ; la section « Reprise de l'histoire » de la bible
comble les trous des chapitres 2 à 7, pas encore construits et à valider par l'auteur.

Musique faite : onze morceaux synthétisés par `src/core/music.gd` (autoload `Music`) à
partir de `data/music.json` ; champ `music` des cartes et des rencontres.

Rendu façon Octopath Traveler : première passe faite (caméra rapprochée `ZOOM` dans
`world.gd`, sol nuancé `ground.gdshader`, eau, rayons `rays` des ambiances, vignette,
talus d'arrière-plan, fougères). Reste, par ordre d'effet : vrai relief jouable, murs
d'intérieur texturés, fonds d'arène plus riches, reflets dans l'eau.

Seconde passe faite : volume automatique des sprites (`PA.relief`), blé repeint, arènes en
gradins (champ `backdrop` de `data/arenas.json`), placement de combat calculé
(`BattleScene.formation`). L'auteur juge le rendu encore loin d'Octopath et ne veut pas
payer de pack : prochaine étape, refonte des personnages par code (plus grands, plus
détaillés), puis relief jouable, maisons, parois d'arène. Voir la fin des décisions de
`docs/SUIVI.md`.

Soirée du 18 novembre (décisions 112 à 123 du suivi) : sauvegardes multiples, musique
recomposée, interface refaite (`ui_kit.gd`), équipe de quatre au plus avec réserve sans
expérience de combat, chapitre 3 (Fondue-Combe) jouable, styles d'architecture par les
données (`"style": "elfe"`), arènes dégagées et combat mis en page façon Octopath (bloc
`stage`, champ `foreground`, `battle_ui.gd`). Restent : écran de paramètres, chapitres 4 à
7 avec un jeu de décors par peuple, personnages plus grands et plus détaillés.

Nuit du 18 novembre (décisions 124 à 132) : nouveau titre, équipement à cinq emplacements
(précision, esquive, critique), écran de paramètres (autoload `Settings`), une arène par
lieu (champ `arena` des cartes), chapitre 4 (Mines de Morbier, style « nain », Glandoulf
quitte l'équipe et Sam mène), points d'élan et icônes de combat (`Sprites.icon`).
Références : `docs/BESTIAIRE.md` (créatures et réponses de l'auteur), `docs/AMBIANCES_COMBAT.md`
(arènes prévues), bible (scénario des chapitres 5 à 7). Suite : relecture visuelle, mort de
Bromure, chapitre 5.

Journée du 18 novembre, suite (décisions 133 à 139) : chapitre 5 jouable (styles de décor
des cavaliers dans `rider_painter.gd` et `rider_builder.gd`, groupe scindé par
`GameState.bench`), personnages refondus en cases de 88×132, maisons de village variées
(`house_builder.gd`), lanterne des Mines, conseils de jeu (`data/tutorials.json`, autoload
`Tutorial`), dépôt GitHub (`origin`), installation Windows (`installer_windows.bat`). Suite :
relecture visuelle d'ensemble, relief jouable, chapitres 6 et 7.

Soirée du 18 novembre (décisions 140 à 144) : construction par `./build.sh` ou `build.bat`,
mise en scène des combats calculée (`BattleScene.layout()`), ambiance des arènes et boss
imposants, seconde passe des personnages, repère de quête, raccords d'histoire. Restent
faibles : monstres peints petits, boss accompagnés de sbires, rayons timides, toits (mousse,
tuiles manquantes), aide des touches à la manette, intérieurs peu revus. Suite : relief
jouable, chapitres 6 et 7.

## Pièges connus

- Une faiblesse listée dans le rapport d'un agent devient une tâche : l'auteur veut qu'elles
  soient corrigées, pas seulement notées.
- Toute retouche de la taille des sprites ou de l'interface de combat se vérifie avec
  `_test_battle_staging` (toutes les arènes, deux tailles d'écran).
- Mesurer l'équilibre : `GLAN_ONLY_MEASURE=1 Godot --headless --path . res://tests/smoke_test.tscn`.

- Un agent secondaire peut signer son commit d'un autre nom de modèle : vérifier la ligne
  `Co-Authored-By` avant chaque fusion.
- Avant `git worktree add -b`, vérifier que la branche n'existe pas déjà : sinon l'agent
  travaille dans un vieux dossier resté sur une ancienne version.

- Toute carte où l'on peut se battre déclare son `arena` et figure dans la table `expected`
  de `_test_arena_by_place` ; le sol d'une arène garde `flatten` ≤ 0,35 et `desat` ≤ 0,2.
- Tout nouveau boss se règle avec l'élan compris (les combats simulés s'en servent).
- Après une fusion, vérifier que le test affiche bien son total de vérifications : une
  erreur de syntaxe dans `tests/smoke_test.gd` le fait tourner à vide sans rien dire.

- Chantiers en parallèle : un worktree par agent, chemins absolus dans son brief, fusion par
  l'agent principal ; le conflit dans `tests/smoke_test.gd` se résout en gardant les deux côtés.
- Les tests de déroulé (`_test_chapter_2`, `_test_chapter_3`) jouent au-dessus du niveau
  attendu pour ne pas dépendre du hasard : l'équilibre se mesure dans les tests `_data`.

- Toute carte doit avoir un champ `music` connu de `data/music.json` (le test le vérifie).
  Écouter les morceaux sans lancer le jeu : `Godot --headless --path . -s
  tests/_dump_music.gd -- <dossier>` écrit un .wav par morceau.
- Les voix d'un morceau doivent tomber juste : la durée du morceau est un multiple de la
  durée de chaque voix (une voix courte se répète).

- Planches de personnages : colonnes 0-2 repos, 3-6 marche, 7-10 attaque, sort, coup reçu,
  KO. Tout dessin doit rester à un pixel au moins des bords de sa case (le test le vérifie).
- Voir les sprites sans lancer le jeu : `Godot --headless --path . -s tests/_dump_sheets.gd
  -- <dossier>` écrit planches, portraits et monstres agrandis.

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
