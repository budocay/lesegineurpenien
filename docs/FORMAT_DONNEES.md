# Format des fichiers de contenu

Tout le contenu du jeu est dans `data/`, en JSON. Le moteur (`src/`) ne contient ni carte,
ni réplique, ni personnage. Ajouter un fichier dans `data/maps/` ou `data/dialogues/`
suffit : il est chargé au démarrage.

Après toute modification, lancer le test automatique décrit dans `docs/SUIVI.md` : il
signale un dialogue manquant, un passage vers une carte inexistante ou un personnage
enfermé.

## `data/game.json`

Titre, sous-titre et point de départ d'une nouvelle partie (`start` : carte, point
d'arrivée, équipe de départ).

## `data/characters.json`

Un objet par personnage, rangé par identifiant.

- `name` : nom affiché dans les dialogues. `full_name` : nom complet (facultatif).
- `role`, `branches` : rôle et noms des deux branches de talents (le détail des talents
  est dans `data/talents.json`, voir plus bas).
- `look` : description utilisée pour dessiner le personnage.
  - `build` : `petit` (Grobitte), `enfant`, `grand`.
  - `outfit` : `tunique`, `robe`, `jupe`, `tablier`.
  - `skin`, `top`, `bottom`, `belt`, `hair`, `boots` : couleurs (`"#rrggbb"`).
  - `hair_style` : `court`, `long`, `boucles`, `chignon`, `chauve`.
  - `beard` : `none`, `longue`, `moustache`, `courte` ; `beard_color`.
  - `hat` : `none`, `magicien`, `toque`, `casquette`, `capuche`, `chapeau_paille`,
    `foulard` ; `hat_color`, `band`.
  - `item` : `baton`, `pipe`.
  - Facultatifs (dessin des personnages) : `cape` (couleur d'une cape dans le dos),
    `eye` (couleur des yeux), `ears` (`elfe` : longues oreilles pointues), `crest`
    (`cornes` : cornes sur un `heaume`). Les planches peintes par code font 48 x 72 px
    par case et s'affichent à 32 pixels par unité.

## `data/ambiances.json`

Une ambiance règle la lumière d'un lieu : couleur de fond, lumière ambiante, soleil
(couleur, force, direction), brume, brume volumétrique, halo, exposition, saturation,
contraste, et particules (`fireflies`, `pollen`, `leaves`, `dust`, `fire`, `embers`, `embruns`, `feuilles_dorees`, `lueurs`,
`smoke`).

Champ facultatif `rays` : des rayons de lumière obliques plantés dans le lieu.
`{"density": 0.006, "color": "#ffc88a", "strength": 0.03}` ; `density` est le nombre de
rayons par case (3 au moins, 40 au plus), `strength` leur force (rester sous 0.08, le
test le vérifie : au-delà ils font une brume grise), `height` et `tilt` sont facultatifs.

Champ facultatif `lantern` : lumière propre du héros et des personnages dans un lieu sombre.
`{"color": "#ffd9a0", "energy": 1.4, "range": 7.5, "halo": 3.4, "halo_alpha": 0.32, "rim": 0.7}` :
le héros porte une lanterne (lumière ponctuelle sans ombre), un halo doux le suit au sol et un
liseré clair souligne sa silhouette ; les autres personnages n'ont que le halo et le liseré,
plus discrets. Absent : aucun effet. Posé sur les ambiances des Mines de Morbier,
du lac noir, des monts de Morbier et des portes de l'Est.
Règle (vérifiée par le test) : toute ambiance sans soleil dont la lumière ambiante est inférieure
à 0,55 a sa lanterne, sauf `interieur_chaud` (éclairée par les foyers). Posé aussi sur le
Garde-Manager, l'étage du Poney de nuit et les caves de Persillé. Une clé en double dans
`ambiances.json` masque la première sans bruit : le test les refuse.

Décor `fern` (fougère) utilisable dans les cartes comme `bush` ou `rock`. Les talus du
nord, le sous-bois au pied des arbres et les plaques de teinte du sol sont posés
automatiquement sur les cartes d'extérieur.

Arènes (`data/arenas.json`) : champ facultatif `backdrop`, le fond de l'arène, construit
par `src/battle/arena_decor.gd`.
`{"tile": "rock_face", "top": "grass", "far": "hills", "sky": ["#2a2250", "#c0705a"],
"shadow": "#3a3340", "jitter": 1.0, "steps": [[-9.5, 1.3], [-13.5, 2.9]]}`

- `steps` : les gradins, `[profondeur du bord, hauteur]`. Chaque gradin est découpé en
  blocs de 2,4 à 6,2 unités dont la hauteur varie par paliers et dont le bord avance ou
  recule (décrochements) ; `jitter` (1 par défaut, 0 = lisse) règle cette irrégularité.
  Les décors de la zone `back` se posent à la hauteur du bloc sur lequel ils se trouvent.
- `tile` : texture des parois (`rock_face`, `rock_face_moss`, `rock_face_mud`,
  `rock_face_dark`, `rock_face_ashlar` ou tout autre type de sol/mur) ; `top` celle du
  dessus (par défaut le sol de l'arène) ; les bords du dessus reçoivent une lèvre de
  gazon et une ombre au pied. `shadow` : couleur du trait d'ombre sous la lèvre.
- `far` : le lointain peint derrière la paroi, `hills`, `forest`, `marsh`, `town` ou
  `cavern` (`src/gfx/horizon_painter.gd`) ; `sky` : `[haut, bas]` du dégradé de ciel.

Une arène est une scène vide et dégagée, comme une piste éclairée : les combattants se
tiennent sur un sol nu, uni, à grain fin ; une nappe de lumière chaude éclaire le centre et
le sol s'assombrit vers les bords ; le décor est repoussé au fond (plus sombre, moins
saturé, légèrement brumeux). Règle générale, appliquée par le code et vérifiée par le
test : aucun décor (semé, posé avec `at` ou poteau de lanterne) ne se trouve à moins de
z = -9,5 du centre de la scène sur |x| < 12 (`BattleScene.STAGE_BACK`, `STAGE_SIDE`) ;
les décors qui y tomberaient sont écartés. Les décors vivent donc au fond (z < -9,5) et
sur les côtés extrêmes. Champs de `backdrop` en plus : `dim` (0,6 par défaut : le fond est
assombri), `desat` (0,35 : désaturation), `haze` (0,2 : brume de distance, couleur tirée
du bas du ciel), tous trois entre 0 et 1.

Champ facultatif `stage` (réglage de la lumière de scène, tout est facultatif) :
`{"light": "#ffd08a", "boost": 1.1, "key": 2.6, "edge": 0.12, "flatten": 0.62,
"grain": 0.05, "desat": 0.3, "vignette": 0.65, "radius": [12, 7.5], "center": [0, -0.5]}`

- `light` : couleur de la nappe de lumière du sol et de la lumière d'appoint ; `boost` :
  éclat ajouté au centre du sol ; `key` : énergie de la lumière d'appoint (large et douce,
  sans ombre, au-dessus de la scène : elle détache les combattants).
- `edge` : luminosité du sol aux bords (1 = aucune vignette de sol, 0,1 = presque noir) ;
  `radius` : demi-largeur et demi-profondeur de la nappe ; `center` : son centre `[x, z]`.
- `flatten` : 0 laisse la texture du sol intacte, 1 la remplace par sa couleur moyenne ;
  `grain` : amplitude du grain fin ; `desat` : désaturation du sol (0 à 1).
- `vignette` : force de l'assombrissement des coins de l'écran (0,45 par défaut).
- Valeurs par défaut du sol : `flatten` 0,15, `grain` 0,04, `boost` 0,45, `edge` 0,45,
  `light` `#ffe9c8`. La nappe de lumière éclaircit sans changer la teinte du sol.
- Lisibilité (champs ajoutés ; la lumière d'une arène se règle pour que les combattants se
  détachent toujours, voir plus bas « Lisibilité garantie ») : `dim` (1 par défaut) assombrit le
  sol seul ; `exposure` (multiplie l'exposition de l'ambiance, 1 par défaut ; sombre : jusqu'à
  1,6) ; `saturation` et `contrast` (remplacent ceux de l'ambiance) ; `fill` (0 par défaut) :
  énergie d'une lumière d'appoint chaude, plus basse et devant les combattants, sans ombre,
  `fill_color` sa teinte ; `lift` (0,1 par défaut) : part de leur couleur que les combattants
  rendent en lumière propre (ils restent lisibles dans le noir sans qu'on éclaire le décor) ;
  `rim` (1 par défaut) : force du liseré clair de leur silhouette (uniform `rim` de
  `sprite.gdshader`) ; `shafts` : `{"color": "#ffe6b0", "strength": 0.08, "slant": 0.55}`,
  larges rayons de lumière obliques posés sur l'image, sous l'interface (`shafts.gdshader`,
  force 0,12 au plus).
- `variation` : amplitude des plaques de teinte du sol (0,09 par défaut) ; `tint` : couleur
  qui multiplie tout le sol (teinte du lieu, `#ffffff` par défaut).
- `patches` : `{"tile": "grass", "amount": 0.3, "tint": "#ffffff"}`, seconde matière par
  taches sur le sol de base (herbe dans l'humus, vase dans l'herbe) ; `tile` est une tuile
  de `Sprites`, `amount` la part couverte (0 à 1), `tint` sa teinte.
- `puddles` : `{"amount": 0.14, "color": "#3f6a68"}`, flaques plates (`amount` au plus 0,4).
- `fleck` : `{"density": 0.05, "colors": ["#ffffff", "#f2d040"], "tuft": "#7dbd58"}`, semis
  de fleurs (pétales, coeur) et de touffes peints à plat sur le sol, rien qui dépasse ;
  `density` par case de 4 pixels (au plus 0,2).
- Le sol de chaque arène doit être celui de son lieu (pas de terre nue : `ground` ne vaut
  jamais `soil`) et garder sa texture (`flatten` au plus 0,35, `desat` au plus 0,2).

Lisibilité garantie. Mesure (capture 1280 x 720, luminance moyenne de l'image sans interface, puis
sans combattants pour la luminance du fond, et des seuls pixels des combattants contre ce qu'ils
cachent) : fond de 0,20 à 0,50, contraste combattants / sol derrière eux d'au moins 0,09 (mesuré :
0,09 à 0,33). Règles générales : la nappe de lumière du sol est resserrée sur le combat (`radius`
de 8 à 11 sur 5 à 7,5) et le sol tombe dans l'ombre autour (`edge` 0,34 au plus sauf arène
sombre) ; la vignette est d'au moins 0,5 ; le fond est flou (profondeur de champ) et plus sombre
que le sol ; les combattants ont un liseré clair (`rim`) et un peu de lumière propre (`lift`) ;
une arène sombre est relevée (`exposure`, `fill`, `lift`), une arène claire est assombrie (`dim`
du sol, teinte, `backdrop.dim`). Le test `_test_arena_mood` fait respecter ces fourchettes
(chaque champ ci-dessus a la sienne) ; les ombres de contact sont franches sous chaque
combattant ; l'occlusion ambiante est coupée en combat (des sprites plats y gagnent des carrés
sombres) et la brume de grandes particules est lissée.

Champ facultatif `foreground` (liste, vide par défaut) : accessoires posés au tout premier
plan, entre la caméra et les combattants, que le flou de profondeur rend flous (cadrage à la
Octopath). Chaque entrée : `{"prop": "rock", "count": 4, "scale": 1.15, "x": [-8, 8]}`.
`prop` est un accessoire connu de `Sprites`, `count` leur nombre, `scale` leur taille, `x` ne
sert plus qu'à choisir le coin (milieu de la bande négatif : coin gauche, positif : coin droit,
sinon un sur deux). Placement déterministe (graine = arène). Ces accessoires ne comptent pas
dans les accessoires de scène vérifiés par le test.
Le premier plan n'est qu'une amorce de photo, et le code l'y tient (`BattleScene.refit_foreground`,
aucune valeur par arène) : chaque accessoire est assombri (`FG_DIM`), flou, et cadré dans l'un
des deux coins bas de l'écran (20 % de la largeur, 26 % de la hauteur) ; il ne passe jamais devant
un combattant (poses comprises), une plaque d'ennemi, une fiche, la frise ni le menu ; chaque coin
en couvre au plus 6 % de l'écran. Un accessoire qui ne peut pas tenir ces règles est d'abord
rapetissé, puis enfoncé dans le sol, puis rapproché du bord, puis retiré (pour cette rencontre
seulement : un combat à moins d'ennemis lui rend sa place). Inutile donc d'en mettre beaucoup :
deux ou trois accessoires bas par arène suffisent.

Vue de combat : caméra basse (hauteur 4,7, recul 13,6, champ 28) qui plonge légèrement ; les
ennemis à gauche, les héros à droite en colonne décalée (chacun un peu plus bas et plus à
droite), les deux files de la frise des tours viennent de `engine.preview(10, acteur)`.
Mise en page de la zone de jeu et de l'interface (`BattleScene.layout`, calculée, aucune
valeur par arène) : l'interface réserve les fiches de l'équipe (coin haut droit, 300 px de large,
71 px par héros : `BattleUI.cards_zone`) et la bande du haut (frise des tours, cartouches :
`BattleUI.top_band`, 134 px). Les héros prennent la plus grande taille d'affichage
(`Actor.set_view_scale`, au plus `HERO_K_MAX` fois la planche, dont les cases de 88 x 132 px sont
trop grandes pour un combat) pour laquelle, dans toutes leurs poses (pas en avant, penché, sort
lancé : `Actor.pose_reach`), ils ne touchent ni les fiches, ni la frise, ni le bord de l'écran ;
au besoin leur colonne descend vers la caméra. Les monstres prennent ensuite la plus grande taille
(au plus `FOE_K_MAX`) qui tient entre la frise, le bas de l'écran (leur plaque comprise) et les
héros ; un ennemi dessiné comme un personnage (`character`) prend la taille des héros. Un boss
large se réduit donc tout seul s'il le faut. Un boss (repéré par `BattleScene.find_boss` : l'ennemi nommé par le champ `boss` de la rencontre ; sinon, si la musique est `boss` ou la fuite impossible, l'ennemi seul ou celui qui a au moins 1,5 fois les PV du suivant ; un combat ordinaire n'en a pas) prend ensuite toute
la place qui reste, jusqu'à `BOSS_RATIO_MAX` (3,4) fois la hauteur d'un héros (plancher vérifié
par le test : 2,2), en descendant au besoin vers la caméra ; face à un boss, les héros sont un peu
plus petits (`BOSS_HERO_K`). Le camp du boss est composé à part (`BattleScene._boss_spots`) : le boss
se tient en retrait (`BOSS_BACK`), au centre de son camp et jamais collé au bord (`BOSS_AIR`) ; ses
sbires, plus petits (`MINION_K`), sont devant lui (`BOSS_FRONT`), de part et d'autre, sur deux rangs
au besoin. Il penche et bondit moins qu'un petit monstre (`Actor.heavy`, `BOSS_HEAVY`). Les monstres
peints par code sont dessinés directement à la définition des héros (`MonsterPainter.paint_hd`, grille
quatre à six fois plus fine que la planche logique de `paint`, grain de matière, verrues, pores, poils,
contour épais ; mise en cache dans `user://cache_monstres/`) : un boss agrandi n'a plus des pixels dix
fois plus gros que ceux des héros. `scale` d'un ennemi (`data/enemies.json`) reste sa
taille relative aux autres monstres.
Autres réglages calculés : le pas en avant de
chaque combattant est réduit au besoin pour ne recouvrir aucun voisin ; les plaques des
ennemis se placent sous leur sprite visible puis s'écartent entre elles et des sprites
voisins ; le menu et la liste du héros qui joue cherchent la place libre la plus proche de
leur position préférée, hors combattants, plaques, fiches, frise, bandeau, aide et premier plan.

Champ facultatif `particles` (liste, vide par défaut) : particules d'ambiance du combat
(`fireflies`, `pollen`, `leaves`, `dust`, `fire`, `embers`, `smoke`). Elle remplace celle
de l'ambiance : en combat, les lucioles flottant devant les combattants et les rayons de
lumière obliques sont retirés pour ne rien masquer, et la brume est allégée.

Champ facultatif `features` (liste) : éléments au sol ou en toile de fond.

- `{"kind": "pool", "pos": [x, z], "size": [largeur, profondeur], "material": "water"}` :
  une mare au contour irrégulier. `material` : `water`, `swamp` (eau trouble du marais),
  `mud` ou `lava` (éclairage orangé ajouté ; `light`, `light_energy`, `energy`
  facultatifs). `bank` : couleur de la berge (`"#00000000"` pour aucune).
- `{"kind": "houses", "list": [{"x", "z", "w", "d", "height", "roof_height", "roof",
  "door", "door_color", "windows"}]}` : façades de maisons posées sur la paroi (même sens
  que les maisons des cartes ; `x` est le bord gauche, `z` le bord du fond).

Dans `props` d'une arène : en plus de `zone`, `count`, `min_dist` et `scale`, `area`
(`[x0, z0, x1, z1]`) limite le semis à un rectangle et `at` (`[[x, z], ...]`) pose
chaque décor à un endroit précis (le nombre est alors celui de la liste). Les décors
d'arène posés avec `at` restent derrière z = -3,8 (le test le vérifie). Le champ `glow`
d'un décor (table `PROPS` de `map_builder.gd`) éclaire son sprite (brasero, forge).

Décors ajoutés (utilisables aussi dans les cartes) : `boulder`, `stump`, `log`,
`mushrooms`, `reeds`, `haystack`, `fence`, `pillar`, `brazier`, `anvil`, `forge`,
`deadtree`. Les arbres `tree` ont quatre essences (chêne, bouleau, sapin, érable roux).
Sols ajoutés : `basalt` ; parois `rock_face*` (96 x 96 px, soit 4 unités).
Maisons des cartes : champ facultatif `awning` (`false` retire l'auvent de la porte). Les
maisons du style par défaut se construisent dans `src/world/house_builder.gd` (voir « Maisons
des villages » plus bas).

## Cartes — `data/maps/<identifiant>.json`

Repère : une case vaut une unité. `x` va vers la droite, `y` vers le bas de la carte, donc
vers la caméra. Deux façons de donner un emplacement :

- `"pos": [x, y]` désigne une case ; l'objet est posé **au centre** de cette case (les
  décimales sont permises) ;
- `"rect": [x, y, largeur, hauteur]` est un rectangle en coordonnées brutes.

Champs principaux :

- `id` (identique au nom du fichier), `name`, `region` (affichés à l'arrivée) ;
- `size` : `[largeur, hauteur]` en cases ;
- `interior` : `true` pour un intérieur (les murs du fond et des côtés sont posés tout
  seuls là où le plancher touche le vide), `wall_height` ;
- `ambiance` : identifiant dans `ambiances.json` ;
- `ramollissement` : nombre entre 0 et 0,9 (absent : 0). C'est la part des dégâts
  physiques perdue par tout le monde dans les combats lancés depuis cette carte ; un
  témoin s'affiche en haut à gauche ;
- `camera` : `distance`, `pitch` (inclinaison en degrés), `fov`, `dof` (force du flou),
  `bounds` facultatif ;
- `ground` : `default` (sol par défaut) puis `fills`, une liste de rectangles peints dans
  l'ordre. Sols : `grass`, `path`, `cobble`, `planks`, `soil`, `floor`, `water`
  (infranchissable), `void` (vide, infranchissable) ;
- `heights` et `stairs` : relief jouable des cartes d'extérieur (voir plus bas, « Relief ») ;
- `spawns` : points d'arrivée nommés, `{"pos": [x, y], "facing": "down"}` ;
- `on_enter` : dialogues joués à l'arrivée, `{"dialogue": "...", "unless": "drapeau"}` ;
- `objects` : la liste des objets.

Objets (champ `type`) :

| Type | Rôle | Champs utiles |
|---|---|---|
| `house` | maison | `rect`, `height`, `roof_height`, `roof` (`rouge`, `vert`, `ardoise`, `chaume`), `door` (position de la porte depuis le bord gauche), `windows`, `door_color`, `lit`, puis `to` (porte qui mène ailleurs) ou `dialogue` (porte fermée) |
| `npc` | personnage | `id`, `pos`, `facing`, `dialogue` (par défaut : son identifiant), `wander` (rayon de promenade), `reach` |
| `warp` | passage | `rect`, `to: {"map", "spawn"}` |
| `trigger` | zone qui lance un dialogue | `rect`, `dialogue` |
| `lantern` | lanterne | `pos`, `shadow` |
| `light` | lumière seule | `pos`, `height`, `color`, `energy`, `range` |
| `fence` | clôture | `points` (ligne brisée), `lean` |
| `scatter` | semis aléatoire | `prop`, `rect`, `count`, `min_dist`, `seed`, `on` (sols autorisés), `avoid` (liste de rectangles `[x, y, l, h]` à laisser vides) |
| `table`, `stool`, `counter`, `fireplace`, `stove`, `rug`, `crate` | mobilier | `pos` ou `rect` |
| `tree`, `bush`, `rock`, `barrel`, `sign`, `bollard`, `monument`, `boat`, `shelf`, `window`… | décor | `pos`, `variant`, `lean`, `height` |

### Relief

Deux champs facultatifs (extérieurs seulement ; une carte qui n'en a pas se comporte comme
avant) donnent de vrais plateaux sur lesquels on marche, des falaises entre deux niveaux et
des rampes pour passer de l'un à l'autre :

```json
"heights": [
	{"rect": [29, 2, 8, 6], "h": 1.2}
],
"stairs": [
	{"rect": [32, 8, 2, 2], "dir": "up", "from": 0.0, "to": 1.2}
],
```

- `heights` : rectangles **en cases entières** (`rect` : x, y, largeur, hauteur) portés à la
  hauteur `h` (en unités ; le sol normal est à 0, un personnage mesure environ 1,9). Le
  dernier rectangle écrit gagne en cas de recouvrement.
- `stairs` : rampes, elles aussi en cases entières. `dir` est le sens de la **montée** :
  `up` monte vers le haut de la carte (y décroissant), `down` vers le bas, `left` vers la
  gauche, `right` vers la droite. `from` est la hauteur au bout bas, `to` au bout haut
  (défauts 0 et 1). La rampe se dessine en marches ; la hauteur du sol y varie de façon
  continue sur toute sa longueur.
- Là où deux cases voisines n'ont pas la même hauteur, le moteur bâtit tout seul une paroi de
  roche (texture `cliff`), un liseré d'herbe au sommet et une ombre au pied, et ce bord
  devient infranchissable. Les bouts d'une rampe doivent donc toucher un sol de hauteur
  `from` (en bas) et `to` (en haut), sinon on ne peut pas l'emprunter ; ses côtés sont des
  parois. Le test automatique vérifie ces raccords et que tout est atteignable à pied.
- Les objets (`pos`), personnages, lumières, clôtures et semis suivent la hauteur du sol
  sous eux ; les semis évitent les bords et les rampes. Les déclencheurs, passages, points
  d'arrivée et zones de rencontres restent en coordonnées de carte (x, y) : la hauteur ne
  change rien.
- Règles de bon goût : laisser les plateaux à une case au moins du bord de la carte ; ne pas
  les poser sous une `house` ni sur l'eau ; ouvrir la rampe vers un chemin ou un espace
  dégagé ; mettre les parois du côté du bas de la carte (face à la caméra), car une paroi
  tournée vers le nord est cachée par son plateau et une zone située juste derrière un
  plateau (environ deux cases pour 1,2 de haut) disparaît à l'écran.

Tout objet qui porte un champ `dialogue` devient examinable ; `label` change le texte de
l'invite (« Parler », « Lire », « Examiner »…) et `reach` la distance d'interaction.

## Maisons des villages (style par défaut)

Chaque `house` d'une carte sans style est construite par `src/world/house_builder.gd`
(textures dans `src/gfx/house_painter.gd`) : toit à deux pans débordant avec rives, faîtage,
cheminée qui fume, lucarnes, marche de seuil, soubassement, enseigne, accessoires, fenêtres
éclairées. Tout ce qui n'est pas dans le JSON est tiré **de façon stable** de l'identifiant
de la carte et de `rect` (la même maison est identique à chaque lancement) : matière du mur,
couleur d'enduit, hauteur, volets, lucarnes, côté de la cheminée. Tout champ donné dans le
JSON l'emporte sur le tirage. `rect`, `door`, `windows`, `to`, `dialogue`, `lit`, `door_color`,
`roof`, `height`, `roof_height`, `awning`, `chimney` gardent leur sens.

Champs facultatifs, tous ignorés quand ils manquent :
- `style` : `"grobitte"` pour une maison de Grobitte : toit d'herbe en tonneau (le champ `roof`
  est ignoré), murs bas, porte ronde et hublots. Les autres maisons ont une porte à planches
  (cintrée ou plate) et des fenêtres à croisillons.
- `wall` : `"crepi"`, `"colombage"`, `"pierre"` ou `"planches"`. Par défaut : tirage selon le toit
  (chaume : planches ou colombage ; ardoise : pierre ou crépi) ; une maison de 3,3 ou plus de
  haut a deux niveaux et le plus souvent un colombage.
- `plaster` : couleur d'enduit, `"#rrggbb"` (crépi, colombage, lucarnes).
- `storeys` : 1 ou 2. À deux niveaux (par défaut dès `height` >= 3,3), l'étage est en
  encorbellement (`jetty` : `false` le supprime) et la façade porte deux rangées de fenêtres.
- `dormers` : nombre de lucarnes sur le pan avant (0 à 2 ; par défaut tiré pour les toits hauts
  et larges, jamais sur une maison à deux niveaux ni une maison grobitte).
- `sign` : enseigne suspendue (`"auberge"`, `"fromage"`, `"forge"`, `"cheval"`, `"herbes"`,
  `"horloge"` pour la mairie, `"blason"` pour la capitainerie). Sans ce champ, elle se déduit du
  nom de la carte visée par `to` ou du `dialogue` de la porte (`auberge`, `poney`, `fromag`,
  `forge`, `ecurie`, `mairie`, `capitain` ou `garde`, `cure`). Pas d'enseigne sur une façade de
  moins de 6.
- Unicité : deux bâtiments d'une même carte ne partagent jamais mur + toit + couleur de porte
  (le test le vérifie). Dans l'ordre du fichier, ce que le JSON n'impose pas (`wall`, puis
  `roof`, puis `door_color`) est modifié pour lever le conflit. Les toits de tuiles, d'ardoises
  et de chaume vieillissent seuls : teinte variable d'une assise à l'autre, mousse vers
  l'avant-toit, quelques tuiles manquantes, ombre des lucarnes ; le toit d'herbe des Grobittes
  est plus clair, avec une crête lumineuse et des raies de gazon qui suivent la courbe.
- `extra` : accessoire contre le mur, loin de la porte (`"barrel"`, `"crates"`, `"flowers"`,
  `""` pour aucun) ; tiré au hasard sinon.

Lumière : les fenêtres éclairées brillent pleinement au crépuscule et la nuit, et s'adoucissent
dans une ambiance à soleil fort (lecture de `sun.energy` de l'ambiance, aucune lumière avec ombre
en plus). `lit: false` éteint toujours les fenêtres. Toutes les pièces d'une maison s'estompent
ensemble quand elle passe devant le héros (`occluders`).

## Styles d'architecture : le style elfe

**Règle : le style d'une carte se choisit par les données, jamais par le code.** Une carte
sans champ `style` garde le village rustique des chapitres 1 et 2 (maisons à colombages,
pavés, talus brun). Le champ `"style": "elfe"` à la racine d'une carte active les décors
de Fondue-Combe ; une maison peut aussi porter `"style": "elfe"` seule. Pour donner leur
architecture aux Nains ou à Mordor, on ajoutera de la même façon un style (un peintre
`src/gfx/<style>_painter.gd`, un constructeur `src/world/<style>_builder.gd`, un accrochage
dans `MapBuilder`), sans toucher aux cartes existantes.

### Champs de carte propres au style elfe

- `style` : `"elfe"`.
- `water` : couleurs de l'eau (`deep`, `shallow`, `ripple`, `glint`) ; torrent et bassins.
- `valley` : fond de vallée au nord d'une carte d'extérieur (étages boisés, parois de roche
  claire, cascades). `trees` (arbres par étage, 20), `pine_ratio` (part de pins sur les
  étages hauts, 0,45), `ledges` (liste de `[z, hauteur]`, par défaut quatre étages),
  `falls` (liste de `{x, from, to}` : une cascade par étage de `to` à `from`), `enabled`
  (faux : on garde les talus ordinaires). Les arbres des abords sont ceux du style.
- `wall_tile` (intérieur) : tuile de mur parmi `elf_wall` (arcature aveugle),
  `elf_wall_vista` (baies sur la vallée), `elf_wall_books` (niches de livres),
  `elf_wall_vault` (voûte de pierre grise, grilles) ; `wall_cap` (couleur du chapeau des
  murs), `wall_glow` (part d'auto-illumination des murs, 0,3).
- Ambiances `fondue_combe` (fin d'après-midi dorée, rayons obliques, feuilles dorées, lueurs)
  et `fondue_combe_interieur` (lumière pâle, lueurs).

### Sols (champ `ground`)

`elf_flag` (dallage ivoire), `elf_flag_dim` (dallage assombri), `elf_path` (chemin de gravier
clair), `elf_lawn` (pelouse, aussi celle des abords), `elf_bridge` (tablier de pont ; à poser
sur de l'eau, il est franchissable), `elf_parquet` (parquet de bois pâle), `elf_floor_dark`
(dalles bleu nuit des profondeurs). Les parois du relief utilisent `elf_terrace` (mur de
terrasse à liseré de lierre), les rampes `elf_steps`. Autres tuiles peintes, pour les
constructeurs : `elf_wall`, `elf_wall_vista`, `elf_wall_books`, `elf_wall_vault`, `elf_cliff`
(roche de la vallée), `elf_wood`, `elf_stone`, `elf_column` (fût cannelé), `elf_roof` (toit
bleu-gris), `elf_roof_vert` (toit vert-de-gris), `elf_glow`.

### Maisons

`{"type": "house", ...}` dans une carte `elfe` devient un pavillon : pierre ivoire, façade
à arcs brisés, porche à colonnes fines, toit bas bleu-gris ou vert-de-gris à épi doré.
Mêmes champs que la maison de village (`rect`, `height`, `roof_height`, `door`, `windows`,
`lit`, `to`, `dialogue`, `if`, `unless`), plus `roof` (`"bleu"` par défaut ou
`"vert-de-gris"`), `door_open` (arche ouverte et éclairée ; vrai par défaut si `to`),
`tall` (baies jusqu'à la balustrade), `columns` et `finial` (vrais par défaut), `stretch`
(étirement en hauteur des murs et du toit, 1.22 par défaut : l'emprise ne change pas ; 1.0 rend
les anciennes proportions). `door_color`,
`awning` et `chimney` sont ignorés.
La façade se complète toute seule : un bandeau doré à denticules à mi-hauteur et, dans chaque
travée nue entre deux ouvertures (44 pixels de large au moins, 1,8 case), une baie aveugle
(ogive creuse et vase de pierre) ou une treille chargée de raisin, en alternance ; les
pilastres cèdent la place à ces ornements. Règle des portes (test `_test_door_clearance`, toutes
les cartes) : aucun objet (lampadaire de carte, bannière, statue, haie...) ne se dresse dans la
bande d'une porte de maison (0,9 de part et d'autre, de 0,3 en arrière à 1,6 devant) ni sur
ses deux lampadaires (à 1,25 de la porte), pour ne jamais les cacher.

### Accessoires (sprites debout, comme `tree` ou `bush`)

Champs communs : `pos`, `variant`, `scale`, `height`, `dialogue`, `label`.
`elf_column` (colonne, 2 variantes), `elf_arcade` (rangée d'arcades à arcs brisés, 4 variantes :
1 à 3 arches, la 3 avec balustrade), `elf_tree` (arbre doré, cuivre, bouleau ou vert tendre ;
4 variantes), `elf_pine` (pin taillé, 2), `elf_hedge` (haie taillée : 0 cône, 1 longue haie,
2 boule, 3 arche), `elf_bench`, `elf_statue` (2), `elf_fountain` (vasque à deux étages),
`elf_desk` (pupitre : 0 simple, 1 triple), `elf_forms` (piles de formulaires, 3),
`elf_seat` (siège à dossier brisé, 2), `elf_bookcase` (bibliothèque en ogive, 3),
`elf_table` (0 ronde, 1 ovale), `elf_flowers` (3), `elf_leaves` (feuilles mortes au sol, 3),
`elf_gate` (grande arche d'entrée : 0 large, 1 étroite ; ses deux piles bloquent le passage),
`elf_banner` (bannière, 2 couleurs), `elf_urn` (urne fleurie, 2), `elf_pergola` (treille),
`elf_bridge_face` (face d'arche d'un pont de pierre), `elf_ivy` (lierre pendant, 2),
`elf_stamp` (tampon et encrier).

### Objets construits (propres au style)

- `elf_rail` : balustrade ajourée. `points` (liste de `[x, z]` en cases, au centre de la
  case ; avec `"exact": true`, en unités), `height` (0,95), `solid` (vrai : bloque le
  passage). Elle suit la hauteur du relief.
- `elf_lantern` : lanterne de pierre à verre bleu pâle. `pos`, `height` (2,2), `energy`,
  `range`, `color`, `shadow`.
- `elf_column3d` : colonne en volume, `pos`, `height` (3,4) ; bloque le passage.
- `elf_arcade`, `elf_gate` : le sprite du même nom avec ses obstacles aux piliers.
- `elf_waterfall` : cascade animée. `pos` (pied de la chute), `base` (hauteur du pied),
  `height`, `width`, `pool` (bassin d'écume au pied).
- `elf_pool` : bassin d'eau. `rect`, `y`.
- `elf_counter` : comptoir de bois pâle avec grille de laiton. `rect`, `height` (1,0),
  `grille` (vrai).
- `elf_medallion` : disque d'or et de feuilles posé au sol. `pos`, `radius` (2).

### Particules d'ambiance du style

`embruns` (brume des cascades, posée par les cascades elles-mêmes), `feuilles_dorees`
(feuilles d'or qui tombent), `lueurs` (lueurs bleu pâle flottantes).

## Dialogues — `data/dialogues/*.json`

Chaque fichier contient plusieurs dialogues rangés par identifiant. Un dialogue est une
liste d'instructions lues dans l'ordre :

```json
"exemple": [
	{"text": "Une ligne de narration, sans nom."},
	{"who": "pepin", "text": "Une réplique de Pépin."},
	{"who": "pepin", "name": "Une voix", "text": "Même portrait, autre nom affiché."},
	{"if": "drapeau_deja_pose", "then": [ ... ], "else": [ ... ]},
	{"set": "drapeau_deja_pose"},
	{"choice": [
		{"text": "Oui", "then": [ ... ]},
		{"text": "Non", "then": [ ... ]}
	]},
	{"action": "save"}
]
```

- `who` est un identifiant de `characters.json`.
- `if` accepte une **condition** (voir plus bas) : un drapeau, mais aussi `"item:cale"`,
  `"party:sam"`, ou plusieurs tests reliés par `&`.
- `{"take": "objet", "count": 1}` retire des objets du sac.
- `{"money": 12}` donne des écus (un nombre négatif en reprend).
- `{"shop": "identifiant"}` ouvre une boutique de `shops.json` ; le dialogue reprend
  quand le joueur la referme.
- `set` pose un drapeau dans l'état de la partie ; `if` le teste. C'est ainsi qu'un
  personnage dit autre chose la seconde fois.
- `action` demande quelque chose au jeu : `save` (sauvegarder), `quitte:<identifiant>` ou `quitte:<identifiant>:<meneur>` (le personnage quitte l'équipe pour de bon, Glandoulf à la fin du chapitre 4 ; le second nom, s'il est donné, prend la tête de l'équipe, sinon c'est le suivant de la liste) ou `rest` (repos : toute
  l'équipe retrouve PV et mana). Trois actions du chapitre 5 : `groupe:a,b,c,d` (l'équipe se
  scinde : voir « Groupe scindé » plus bas), `va:<carte>:<arrivée>` (le dialogue emmène
  l'équipe dans une autre carte, une fois fini) et `equipe:<personnage>:<objet>` (le
  personnage équipe l'objet pris dans le sac).
- `{"battle": "identifiant"}` lance une rencontre de `encounters.json`. Le dialogue
  reprend après le combat ; en cas de victoire le drapeau `combat_<identifiant>` est posé,
  ce qui permet d'enchaîner avec `{"if": "combat_<identifiant>", "then": [...]}`.
- `{"give": "objet", "count": 3}` ajoute des objets à l'inventaire (`count` vaut 1 par défaut).
- `{"join": "personnage"}` fait entrer un personnage dans l'équipe (il lui faut un bloc
  `battle` dans `characters.json`). Il arrive un niveau sous le meneur, avec l'équipement
  de son bloc `equip`. Si les quatre places de combat sont prises, il va en réserve et un
  message le dit (voir « Équipe active » plus bas).
- `{"set": "drapeau", "value": false}` retire un drapeau (par exemple à la fin d'une
  invasion).
- `{"chapter": "chapitre_2"}` change le chapitre courant de la partie.
- `{"banner": "Titre", "sub": "Sous-titre"}` affiche le grand bandeau à l'écran (celui
  des arrivées dans un lieu), sans interrompre le dialogue.

## Style nain (Mines de Morbier)

`"style": "nain"` à la racine d'une carte active l'architecture des Nains (chapitre 4), de la
même façon que `elfe` : `MapBuilder` confie la construction à `src/world/dwarven_builder.gd`,
les tuiles et décors se peignent dans `src/gfx/dwarven_painter.gd`. Aucune carte existante
n'est touchée. Les mines se passent dans un fromage de Morbier : pierre bleu-gris veinée,
or, braise des forges, et la raie sombre du fromage dans les murs.

### Champs de carte propres au style nain

- `style` : `"nain"`. `water` : couleurs du lac (`deep`, `shallow`, `ripple`, `glint`).
- Extérieur (Monts) : neige au sol, roche, sapins ; `massif` : étages de roche au nord, liste
  de `[z, hauteur]` (par défaut trois : `[-6, 5]`, `[-13, 9]`, `[-21, 14]`).
- Intérieur : `wall_tile` parmi `nain_mur`, `nain_mur_morbier` (pierre à raie de fromage) et
  `nain_mur_forge` (pierre rougie par les forges) ; `wall_cap` (couleur du chapeau des murs,
  `#15131f`) ; `wall_glow` (part d'auto-illumination des murs, 0,22). Les murs se bâtissent
  seuls au nord, à l'ouest et à l'est des cases de sol voisines d'un trou (`void`). Un
  `nain_abime` est solide sans être un trou : on ne le traverse pas, mais on le voit.
- Le relief (`heights`, `stairs`) est permis dans les intérieurs nains, avec les mêmes règles
  que dans le style elfe (rampe de 2 x 2, `dir` = sens de la montée).
- Ambiances : `neige_morbier` (Monts, neige), `mines`, `mines_forge`, `mines_profondeurs`,
  `lac_noir`, `mines_combat`, `portes_est`.

### Sols et tuiles

`nain_dalle` (dalles sombres), `nain_veine` (dalle à veine d'or), `nain_voie` et `nain_voie_v`
(rail de wagonnet, horizontal et vertical), `nain_pont` (tablier de pont, franchissable sur
un abîme), `nain_marbre` (marbre de la Grande Salle, motif de forge), `nain_pate` (croûte du
(Sols `nain_roche_humide` : roche mouillée bleutée aux flaques reflétant le plafond ; `nain_galets` : bord de l'eau couvert de galets. Utilisés au lac de Maroilles.)
fromage), `nain_abime` (vide solide), `nain_neige`, `nain_sentier`, `nain_roc`,
`nain_marches`, `nain_pierre`, et les murs `nain_mur`, `nain_mur_morbier`, `nain_mur_forge`.

### Accessoires (sprites debout)

Champs communs : `pos`, `variant`, `scale`, `height`, `dialogue`, `label`, `if`, `unless`.
`nain_sapin` (2), `nain_cristal` (3), `nain_wagonnet` (2), `nain_meule` (2), `nain_tombe`,
`nain_registre`, `nain_porte` (2 : fermée, ouverte), `nain_statue`, `nain_squelette` (2),
`nain_panneau`, `nain_stele`, `nain_etabli` (2), `nain_gravats` (3), `nain_neige_tas` (2).

### Objets construits

- `nain_pilier` : pilier carré à bandes d'or, en volume, bloque le passage. `pos`, `height`,
  `size` (1,3).
- `nain_brasero` : brasero allumé. `pos`, `color`, `energy`, `range`, `shadow`.
- `nain_torche` : torche murale. `pos`, `height` (1,9), `color`, `energy`, `range`.
- `nain_parapet` : parapet de pierre crénelé. `points` (comme `elf_rail`), `height` (0,55).
- `nain_dais` : estrade basse. `rect`, `height` (0,25).
- `nain_forge_murale` : gueule de forge dans le mur. `pos`, `width` (3), `energy`, `range`.

### Particules d'ambiance du style

`neige` (flocons des Monts). Les mines reprennent `dust`, `embers` et `lueurs`.

### Monstres peints du chapitre 4 (champ `sprite.species` d'un ennemi)

`gobelin`, `gobelin_pic`, `gobelin_chef`, `chauve` (chauve-souris), `troll`, `guetteur`
(tentacule du lac), `goulum`, `balourd`.

### Conditions

Partout où le contenu pose une condition (`if` d'un dialogue, `start` / `complete` /
`done` d'une quête, `if` d'un article de boutique) :

| Écriture | Vrai quand |
|---|---|
| `"drapeau"` | le drapeau est posé |
| `"!drapeau"` | il ne l'est pas (le `!` marche devant tous les tests) |
| `"item:cale"`, `"item:cale:3"` | le sac contient au moins un, au moins trois exemplaires |
| `"party:sam"` | Sam voyage avec l'équipe (au combat ou en réserve) |
| `"money:40"` | l'équipe a au moins 40 écus |
| `"quest:poele"`, `"quest_done:poele"` | la quête est en cours, est terminée |
| `"a & b & c"` | tous les tests sont vrais |

Attention : le `if` et le `unless` des **objets d'une carte** n'acceptent qu'un drapeau
chacun. Un objet peut porter les deux à la fois : il n'est alors présent que si le drapeau
`if` est posé et que le drapeau `unless` ne l'est pas (les Morfales pendant l'invasion).
Une caisse (`crate`) qui porte un `dialogue` devient un objet à examiner (l'estrade de la
Fête) ; `size` règle sa taille.

## Styles du chapitre 5 : cavaliers, Fongorn, Isengarde-Manger, chutes

Quatre valeurs de `"style"` à la racine d'une carte (code : `src/world/rider_builder.gd`,
peinture : `src/gfx/rider_painter.gd`). Le style change le sol des abords, les falaises, les
marches et parois du relief, le mur des intérieurs, les arbres plantés autour de la carte et le
sous-bois. Les champs `heights`, `stairs`, `ground`, `water`, `wall_tile`, `wall_cap` et `wall_glow`
valent comme pour les autres styles (voir « Relief »). Une carte sans `style` reste rustique.

| `style` | lieu | abords | arbres | intérieur |
| --- | --- | --- | --- | --- |
| `"cavalier"` | plaine du Roquefort, Cabécou, Bergerie d'Or | `cav_herbe` | `cav_arbre` | `cav_mur` |
| `"fongorn"` | forêt de Fongorn | `ent_mousse` | `ent_arbre` | `ent_racines` |
| `"isengarde"` | Isengarde-Manger, Garde-Manger, terrasse de l'Office | `isen_dalle` | `isen_cheminee` | `isen_mur` |
| `"chutes"` | chutes du Gratin | `chu_gravier` | pins `elf_pine` | `chu_mur` |

### Sols et tuiles

Cavaliers : `cav_herbe` (herbe dorée), `cav_chemin` (terre battue), `cav_planches` (planches
dorées), `cav_mur` (rondins dorés), `cav_botte_sol` (paille). Forêt : `ent_mousse`, `ent_sentier`,
`ent_racines`. Isengarde : `isen_dalle` (dalles noires), `isen_fonte` (plaques de fonte),
`isen_farine` (sol enfariné), `isen_fosse` (fosse, bleue quand elle est inondée), `isen_mur`.
Chutes : `chu_roche`, `chu_gravier`, `chu_mur`. Se mettent dans `ground.fills` comme tout sol.

### Accessoires (sprites debout)

`cav_arbre` (2), `cav_botte` (1), `cav_etendard` (2), `cav_brebis` (2), `cav_enclos` (1),
`cav_trone` (1), `cav_lit` (1), `cav_grange` (1) ; `ent_arbre` (3), `ent_panonceau` (1),
`ent_souche` (1) ; `isen_four` (2), `isen_marmite` (1), `isen_cage` (1), `isen_sac` (2),
`isen_cheminee` (1), `isen_pancarte` (1), `isen_tour` (1) ; `chu_pierre` (2), `chu_ecume` (1).
Un accessoire qui porte un `dialogue` devient une interaction, comme les autres.

### Objets construits

- `cav_halle` : grande halle de bois doré (Cabécou, Bergerie). `rect`, `height`, `door` (côté).
- `cav_palissade` : palissade de pieux dorés. `points` (comme `elf_rail`), `height`.
- `isen_flamme` : flamme de four, avec sa lumière. `pos`, `color`, `energy`, `range`.
- `chu_cascade` : chute d'eau en volume qui moutonne en bas. `pos`, `height`, `width`. Elle prend la
  teinte du champ `water` de la carte (corps, creux et écume tirés de `shallow`, `deep`, `glint` :
  jaune de gratin aux Chutes), s'adosse à une paroi de roche sombre plus large qu'elle et pose au
  pied une nappe d'écume qui miroite (`waterfall_foam.gdshader`). `pos` peut se poser sur l'eau,
  hors de portée : elle ne gêne aucun passage.

### Accessoires d'habillage (`src/gfx/decor_painter.gd`)

Utilisables par toute carte, par `prop` d'un `scatter` ou comme objet (`{"type": "vil_banc", "pos": [x, y]}`).
Tous ont un petit obstacle (voir `PROPS` dans `map_builder.gd`) : ne pas les poser au milieu d'un
chemin d'une case, le test vérifie que tout reste atteignable. Village : `vil_puits`, `vil_banc`,
`vil_brouette`, `vil_potager` (3 variantes), `vil_linge` (2), `vil_boite` (boîte aux lettres),
`vil_butte` (2 : fleurs ou pierrier, sans obstacle). Écurie des cavaliers : `cav_ratelier`,
`cav_abreuvoir`, `cav_cheval_bois`, `cav_brasero` (poser un objet `light` chaud au même point).

Ombre sur les sprites : la lumière du soleil n'assombrit un sprite (arbre, personnage) que d'un
tiers de ce qu'elle assombrit le sol (shader `sprite.gdshader`) : l'ombre d'un arbre voisin ne
coupe plus un feuillage en deux moitiés.

### Arènes et panneaux d'arène

Sept arènes en fin de `arenas.json` : `chutes_gratin`, `plaine_roquefort`, `fongorn`,
`bergerie_or`, `garde_manger`, `petrins` (les pétrins de l'Isengarde) et `terrasse_office`. Les
deux arènes d'intérieur (`bergerie_or`, `garde_manger`) utilisent les panneaux peints
`bergerie` et `garde_manger` (champ `panels` de `backdrop`, `src/gfx/arena_panels.gd`).

### Monstres peints du chapitre 5 (champ `sprite.monster` d'un ennemi)

`ouroukouille` (grosse louche et bouclier-couvercle), `ouroukouille_brocheur`,
`ouroukouille_petrisseur` (toque de boulanger), `ouroukouille_chef` (Uglouk), `paton` (boule de
pâte), `ouargue` (loup de colline), `corbeau` (contrôleur), `hirsute` (bûcheron de Dunlande),
`hors_oeuvre` (petit entremets à pattes). Grimace, Froton Anneauté et Sarumâle sont des
ennemis à `sprite.character`.

## Groupe scindé (chapitre 5)

L'équipe se sépare, puis se réunit : tout passe par des actions de dialogue, sans code propre
à un chapitre.

- `{"action": "groupe:sam,froton,merri,pepin"}` : ces personnages forment l'équipe, dans cet
  ordre (le premier mène) ; tous les autres recrutés passent sur le **banc** (`GameState.bench`).
  `groupe:tous` rappelle le banc derrière l'équipe actuelle ; l'équipe de combat reste limitée
  à quatre (`MAX_ACTIVE`), le surplus est en réserve. Un nom inconnu est ignoré (rien ne change
  si aucun nom n'est valable).
- Les fiches (niveau, expérience, équipement, talents) sont conservées. Celui qui revient du
  banc et qui est en retard sur le niveau le plus haut de l'équipe qu'il rejoint est remonté à
  ce niveau (expérience à zéro) ; celui qui est sur le banc ne gagne rien. Personne n'est jamais
  rétrogradé.
- `{"action": "va:fongorn:ouest"}` : à la fin du dialogue, l'équipe est emmenée à cette carte, à
  ce point d'arrivée. À la fin de la scène, la carte est reconstruite avec le nouveau meneur.
- `{"action": "equipe:glandoulf:louche_blanche"}` : équipe l'objet du sac (il faut le `give`
  avant). C'est la symétrique du `quitte:` du chapitre 4 : Glandoulf revient à Fongorn par
  `groupe:glandoulf,...`, et reprend la tête.
- Sauvegarde : le champ `bench` (liste d'identifiants) s'ajoute à `party`. Une sauvegarde sans
  ce champ (d'avant le chapitre 5) se charge avec un banc vide.
- Un objet d'équipement peut porter un champ `skills` (liste d'identifiants de `skills.json`) :
  son porteur apprend ces compétences tant qu'il l'équipe (la Louche Blanche donne
  `veille_de_pierre` et `vrai_repos`).

## Équipe active et réserve

Une équipe ne se bat jamais à plus de **quatre** (`GameState.MAX_ACTIVE`). Structure :
`GameState.party` reste la liste de **tous** les recrutés, dans l'ordre ; les quatre
premiers se battent (`active_party()`), les suivants sont en réserve (`reserve_party()`).
Une sauvegarde n'a donc rien de nouveau : une partie à cinq ou six personnages se charge,
les quatre premiers combattent et les autres sont en réserve.

- `{"join": ...}` d'un cinquième : il va en réserve, avec une notice (« rejoint le groupe,
  en réserve »). Rien à écrire de plus dans les dialogues.
- Les conditions `party:x`, les quêtes, les talents, l'équipement, le sac et les soins
  (`heal_party`) comptent **tous** les recrutés : un réserviste voyage avec le groupe.
- Le combat (`BattleEngine.setup`) ne prend que `active_party()` ; les rencontres
  aléatoires comptent aussi les actifs pour `min_party` / `max_party`. Les combats
  scénarisés qui imposent leur équipe (`party` d'une rencontre, comme Sam seul au bras de
  fer) ne lisent pas l'équipe du joueur et ne changent rien.
- Après une victoire, seuls les combattants gagnent l'expérience : la réserve ne gagne
  rien (`GameState.RESERVE_XP` vaut 0, règle de l'auteur). L'expérience des quêtes, elle,
  va à tous, et une recrue arrive au niveau du groupe (`catch_up`).
- Écran Équipe (Échap, Équipe) : combattants puis réservistes (grisés, « réserve »). La
  fiche d'un personnage propose « Passer en réserve » ou « Entrer dans l'équipe » :
  on choisit alors avec qui il échange sa place (`GameState.swap_members`). Le meneur
  (Glandoulf) ne peut pas quitter la tête de l'équipe par le menu (seule l'action `quitte:` d'un dialogue le retire, au chapitre 4) ; il n'y a donc jamais d'équipe
  vide, et elle compte toujours quatre combattants dès qu'il y a quatre recrutés.

## Quêtes — `data/quests.json`

```json
"bittes": {
	"name": "Sauver les apparences", "kind": "annexe", "giver": "Maître Gédéon",
	"desc": "Texte du journal.",
	"start": "cales_recues",
	"steps": [
		{"text": "Caler les trois bittes du quai", "done": "bitte_1 & bitte_2 & bitte_3"},
		{"text": "Prévenir Maître Gédéon", "done": "bittes_payees"}
	],
	"complete": "bittes_payees",
	"reward": {"money": 30, "xp": 20, "items": {"noeud_cabestan": 1}}
}
```

- `kind` : `principale` ou `annexe`. L'ordre du fichier est l'ordre du journal.
- La quête **démarre toute seule** dès que `start` est vrai et **s'achève toute seule**
  dès que `complete` l'est ; la récompense est alors donnée (une seule fois) et annoncée.
  Les dialogues n'ont qu'à poser des drapeaux. Sans `complete`, la quête reste ouverte.
- `steps` : les étapes affichées, cochées quand leur `done` est vrai. Le journal s'arrête
  à la première étape non faite.
- `reward` : `money`, `xp` (donnée à chaque membre de l'équipe), `items`.
- `target` (facultatif, par étape) : où se trouve l'objectif. Sert au **repère de quête** : une
  marque dorée flotte au-dessus de la cible quand on est dans sa carte ; dans une autre carte,
  le rappel de quête ajoute « vers l'est : Brie » (le trajet est calculé d'après les passages des
  cartes). Une cible est `{"map": "bittebourg", "npc": "pepin"}` (un personnage),
  `{"map": "...", "dialogue": "potager"}` (un objet, une maison ou un déclencheur qui porte ce
  dialogue), `{"map": "...", "pos": [x, z]}` (un point) ou `{"map": "..."}` (la carte seule, sans
  marque). Une liste de cibles est permise (le repère montre toutes celles de la carte). Le test
  vérifie que la carte, le personnage ou le dialogue existent. Le joueur peut couper le repère :
  Paramètres, « Repère de quête » (réglage `repere`).

## Boutiques — `data/shops.json`

```json
"etal_ursule": {
	"name": "L'étal d'Ursule", "keeper": "ursule", "sell_ratio": 0.5,
	"greeting": "Phrase affichée à l'entrée.",
	"stock": [
		{"item": "tisane"},
		{"item": "poele_gamelle", "price": 40, "if": "froton_avoue", "once": "poele_rachetee"}
	]
}
```

Un article prend le `price` de `items.json`, sauf s'il en donne un. `if` le réserve à une
condition ; `once` le rend unique : le drapeau est posé à l'achat et l'article disparaît.
`sell_ratio` est la part du prix rendue au joueur quand il vend. Un objet sans `price`
ne se vend pas.

## Combat

Toutes les règles sont dans `src/battle/battle_engine.gd` ; les chiffres sont ici.

### `data/characters.json`, bloc `battle`

```json
"battle": {
	"element": "contondant", "attack_name": "Coup de bâton",
	"base":   {"hp": 38, "mp": 20, "atk": 6, "def": 4, "mag": 11, "res": 7, "spd": 8},
	"growth": {"hp": 6, "mp": 3, "atk": 0.8, "def": 0.8, "mag": 1.8, "res": 1.2, "spd": 0.5},
	"learn":  {"1": ["etincelle", "baillement"], "2": ["petit_somme"]}
}
```

Statistique au niveau N = `base` + `growth` × (N − 1). `learn` donne les compétences
apprises à chaque niveau. Un bloc facultatif `"equip": {"weapon": "poele_gamelle"}`
donne l'équipement avec lequel le personnage rejoint l'équipe. Un bloc facultatif
`"gear": {"weapon": ["baton"], "head": ["chapeau"], "armor": ["robe"]}` liste les **genres**
d'arme, de couvre-chef et de tenue que le personnage sait porter (voir « Équipement »).

**Statistiques secondaires** (facultatives, dans `base`, `growth` d'un personnage et `stats`
d'un ennemi ; valeurs par défaut neutres) : `acc` précision (100), `eva` esquive (0), `crit`
chances de coup critique en % (6), `critdmg` dégâts critiques en % (150). L'expérience nécessaire pour passer du niveau N au suivant est
`xp_base × N ^ xp_power` (réglés dans `game.json`, bloc `progression`).

### `data/elements.json` et `data/statuses.json`

Un élément a un `name`, un nom court `short` (affiché dans les cases de faiblesse) et une
couleur. Un état a un `name`, une couleur, une durée `turns`, et selon le cas : `dot`
(part des PV perdue à chaque tour), `skip` (fait passer le tour) avec `skip_text`,
`wake_on_hit` (un coup le dissipe), `mods` (multiplicateurs de statistiques, par exemple
`{"atk": 0.7}`), `negative` (dissipé par les soins d'état).

### Élan (règles dans `battle_engine.gd`, constantes `ELAN_*`)

Chaque héros commence le combat avec 1 point d'élan (`ELAN_START`) et en gagne 1 au début de
chacun de ses tours (`ELAN_GAIN`), jusqu'à 5 en réserve (`ELAN_MAX`). Avant d'agir, le joueur
peut en engager de 0 à 3 (`ELAN_COMMIT_MAX`, au plus sa réserve) : touches Gauche/Droite
(ou A/D, ou la croix du pad) dans le menu racine et dans la liste des compétences. L'action
reçoit un champ `elan` (entier). Un tour joué avec de l'élan engagé ne rapporte pas de point
au tour suivant. Les ennemis n'ont pas d'élan. Ni la défense, ni les objets, ni la fuite
n'en consomment ; il n'est pas sauvegardé (il repart à 1 à chaque combat).

Effet selon l'action (`elan_kind`, aucun cas particulier par compétence) :

- attaque de base : `1 + N` coups (chacun écorne le bouclier s'il touche une faiblesse) ;
- compétence offensive (dégâts) : puissance multipliée par `ELAN_POWER` (1, 1,5, 2, 2,5) ;
- soin : montant multiplié par `ELAN_HEAL` (1, 1,3, 1,6, 1,9) ;
- état : sur un allié, `N` tours de plus ; sur un ennemi, la chance de réussite est multipliée par
  `1 + ELAN_STATUS` (0,2) par point ;
- compétence sans effet à amplifier : l'élan n'est pas dépensé.

Champs facultatifs d'une compétence (`data/skills.json`) : `"elan": false` la rend
inamplifiable ; `"elan_scale": [1, 1.4, 1.8, 2.2]` remplace la table de multiplicateurs
(quatre valeurs, pour 0 à 3 points). Le combat automatique des tests engage de l'élan contre
un ennemi ébranlé ou de plus de 600 PV (`ELAN_AUTO_BIG`), et 2 points quand la réserve est pleine.
`commit()` renvoie aussi `gains` (expérience gagnée par héros) pour l'écran de victoire.

### Icônes de combat — `src/gfx/icon_painter.gd`

Icônes de 12 x 12 pixels (la main fait 16 x 16), peintes par code, affichées deux fois plus
grandes. Accès unique : `Sprites.icon(nom)` ; un PNG `assets/sprites/icons/<nom>.png` le
remplace s'il existe. Noms : commandes (`attack`, `skills`, `items`, `defend`, `flee`, `elan`),
éléments (identifiants de `elements.json`), genres d'arme (`baton`, `ustensile`, `dague`,
`serpe`, `rapiere`, `epee`, `arc`, `hache`), états (identifiants de `statuses.json`) et signes
(`hand`, `coin`, `heart`, `mana`, `unknown`, `up`). Un nouvel élément, état ou genre d'arme
doit avoir son icône dans ce fichier (le test automatique le vérifie). Les cases de faiblesse
des ennemis montrent l'icône de l'élément (`contondant` et `tranchant` sont les types de
coup physiques), ou un « ? » tant que la faiblesse n'est pas découverte.

### `data/skills.json` et `data/items.json`

```json
"baillement": {
	"name": "Bâillement contagieux", "cost": 4, "target": "enemy",
	"desc": "Texte affiché dans le menu.",
	"effects": [
		{"type": "damage", "stat": "mag", "power": 70, "element": "torpeur"},
		{"type": "status", "id": "sommeil", "chance": 0.6, "turns": 2}
	]
}
```

- `target` : `enemy`, `all_enemies`, `ally`, `all_allies`, `self`, `ally_ko` (allié à terre).
- Effets : `damage` (`stat` = `atk` contre la défense ou `mag` contre la résistance,
  `power` en pourcentage, `element`), `heal` (`power` fixe, `percent` des PV max, `stat`
  qui s'ajoute), `mana`, `status` (`id`, `chance`, `turns`), `cure` (dissipe les états
  négatifs), `revive` (`percent` des PV rendus).
- Dégâts = statistique × 2 × `power` / 100 − défense, à ±10 %, ×1,5 sur une faiblesse,
  ×`critdmg`/100 en coup critique (150 par défaut), ×1,5 sur un ennemi ébranlé, ×0,5 si la
  cible se défend.
- **Précision et esquive** : un coup physique (`stat` = `atk`) porté à l'autre camp touche avec
  la probabilité `clamp((acc de l'attaquant − eva de la cible) / 100, 0,1 ; 1)`. Les sorts
  (`stat` = `mag`), soins et soutiens ne ratent jamais. Un tirage n'est fait que si la
  probabilité est sous 1, ce qui garde les combats d'avant identiques. Un coup raté produit
  l'événement `{"type": "miss", "target": c, "dodge": true|false}` (`dodge` vrai quand la
  cible a de l'esquive, faux pour le raté de l'état « enfumé »).
- **Critique** : probabilité `min(0,8 ; fx.crit (0,06 par défaut) + (crit − 6) / 100 +
  passif crit)`. L'événement de dégâts porte `crit: true`.
- **Résistances** : le passif `resist` (`{"feu": 0.25}`) multiplie les dégâts de cet élément
  reçus par `max(0,2 ; 1 − valeur)`. `status_resist` (`{"sommeil": 0.5, "all": 0.2}`) multiplie
  la chance de subir un état négatif par `1 − valeur`.
- Un effet `damage` peut porter `"flat": 48` : des dégâts fixes ajoutés avant la défense
  (les fusées de poche, qui frappent aussi fort quel que soit le lanceur).
- Un objet consommable s'écrit comme une compétence, sans `cost`, avec un `price`.
  Hors combat, seuls ceux qui rendent des PV ou du mana à un allié s'utilisent du sac.
- Un **équipement** : `"kind": "equipment"`, `slot` (`weapon` arme, `head` couvre-chef,
  `armor` tenue, `trinket` babiole), `type` (genre : `baton`, `ustensile`, `dague`, `serpe`,
  `rapiere`, `epee`, `arc`, `hache` pour les armes ; `robe`, `cuir`, `mailles`, `plates` pour
  les tenues ; `chapeau`, `casque` pour les couvre-chefs ; libellés dans `game.json`,
  `item_types`), `mods` (bonus ajoutés aux statistiques parmi `hp mp atk def mag res spd acc
  eva crit critdmg`, négatifs permis : c'est ainsi qu'on fait un objet à contrepartie),
  `for` (liste de personnages : réserve l'objet à ceux-là), `passives` (effets permanents :
  `resist`, `status_resist`, `immune`, `regen_hp` en part des PV max par tour, `regen_mp`,
  `money_bonus`, `xp_bonus`, `initiative`, `crit`), `firm: true` (son porteur ignore le
  Ramollissement), `price`, `desc`.
  Qui peut le porter : `for` si présent ; sinon, si l'objet a un `type` et que le personnage a
  une liste `gear` pour cet emplacement, le genre doit y figurer ; sinon tout le monde (les
  babioles n'ont pas de genre).
- **Emplacements** (`GameState.SLOTS`) : `weapon`, `head`, `armor`, `trinket`, `trinket2`. Les
  babioles vont dans les deux derniers ; les identifiants `weapon`, `armor`, `trinket` n'ont pas
  changé. À la lecture d'une sauvegarde, `GameState._clean_equipment` efface les objets
  disparus et les emplacements inconnus et rend au sac ce que le porteur ne peut plus tenir.
  `SAVE_VERSION` vaut 4.
- Un **objet de quête** : `"kind": "key"`, un nom et une description, rien d'autre.
- Dans `statuses.json`, `"firm": true` rend un état protecteur contre le Ramollissement
  (c'est le cas de « Galvanisé »).
- Ramollissement : un coup fondé sur `atk` perd la part indiquée par la carte, sauf si
  celui qui frappe porte un objet `firm` ou subit un état `firm`.
- Effet `steal` (réservé à l'équipe) : vole à l'adversaire la part `percent` de ses écus,
  une seule fois par adversaire ; la somme s'ajoute au butin.
- Dans `statuses.json`, `"taunt": true` fait de celui qui porte l'état la cible de tous
  les coups ennemis à cible unique, et `"evade": 0.3` fait rater 30 % des coups physiques
  qui le visent.

### `data/talents.json`

Un objet par personnage jouable, avec ses deux branches dans l'ordre de `characters.json` :

```json
"glandoulf": {
	"branches": [
		{
			"id": "pyrotechnicien", "name": "Pyrotechnicien", "desc": "Texte de la branche.",
			"talents": [
				{"id": "meche_courte", "name": "Mèche courte", "cost": 1, "desc": "Texte affiché.",
					"passives": {"element_boost": {"feu": 0.15}}},
				{"id": "poudre_seche", "name": "Poudre sèche", "cost": 2, "desc": "...",
					"mods": {"mag": 3}, "skills": ["petarade"], "passives": {"crit": 0.08}}
			]
		}
	]
}
```

- Dans une branche, les talents s'apprennent **dans l'ordre de la liste**. `cost` est le
  prix en points de talent. On gagne `talent_points_per_level` point(s) par niveau
  (`game.json`, bloc `progression`) ; rien au niveau 1.
- Un talent peut apporter, au choix ou ensemble : `mods` (bonus de statistiques, comme un
  équipement), `skills` (compétences de `skills.json` ajoutées au menu de combat),
  `passives` (effets permanents en combat).
- Effets permanents reconnus par le moteur (les valeurs de plusieurs talents s'ajoutent) :
  - `crit` : chances de coup critique en plus (0.1 = 10 %) ;
  - `element_boost` : `{"feu": 0.15}`, dégâts de cet élément augmentés ;
  - `status_chance` : `{"sommeil": 0.35}` ou `{"all": 0.25}`, chances d'infliger un état
    à un adversaire multipliées par 1 + valeur ;
  - `heal_boost` : soins donnés augmentés ; `guard` : part des dégâts reçus en moins ;
  - `counter` : chance de rendre aussitôt un coup physique reçu (attaque de base) ;
  - `regen_hp` (part des PV max) et `regen_mp` (points) rendus au début de chaque tour ;
  - `initiative` : part de l'attente du premier tour en moins (0.5 = joue deux fois plus tôt) ;
  - `money_bonus` : écus de victoire en plus ; `vs_afflicted` : dégâts en plus contre un
    adversaire qui subit un état négatif ; `fury` : dégâts en plus quand les PV baissent
    (valeur atteinte à 0 PV) ; `immune` : liste d'états qui n'ont pas prise.
- Le texte `desc` d'un talent doit dire en clair ce que font ses `passives` : l'écran de
  talents n'affiche tout seul que les `mods` et les compétences.
- Ajouter un personnage jouable : sa fiche dans `characters.json` et ses deux branches ici.

### `data/enemies.json`

```json
"limace_molle": {
	"name": "Limace molle",
	"sprite": {"monster": "limace", "scale": 1.0},
	"stats": {"hp": 44, "atk": 6, "def": 2, "mag": 3, "res": 2, "spd": 5},
	"element": "contondant", "weak": ["feu", "tranchant"], "shield": 2, "immune": [],
	"ai": [{"skill": "attack", "weight": 3}, {"skill": "bave", "weight": 2}],
	"xp": 6, "money": [1, 3], "drops": [{"item": "tisane", "chance": 0.15}]
}
```

Un ennemi peut porter les statistiques facultatives `acc`, `eva`, `crit`, `critdmg` dans
`stats` (par exemple `"eva": 10` pour une mouche). Les butins (`drops`) servent aussi à
trouver de l'équipement : `{"item": "dent_rat_cave", "chance": 0.08}`, ou `1.0` pour la
pièce rare d'un boss.

`sprite` désigne soit un monstre dessiné (`monster`), soit un personnage de
`characters.json` (`character`) ; `scale`, `hover` (hauteur de vol) et `glow` sont
facultatifs. `ai` est un tirage pondéré entre l'attaque de base et des compétences.
Un boss peut changer de tactique quand il faiblit : `"low_at": 0.5` (part des PV, 0,5 par
défaut) et `"ai_low": [...]`, une seconde liste utilisée sous ce seuil.
Monstres dessinés disponibles : `limace`, `baveuse`, `guepe`, `frelon`, `champignon`, `amanite`,
`epouvantail`, `sanglier`, `solitaire`, `grenouille`, `crapaud`, `sangsue`, `follet`, `rat`, `coq`, `asticot`, `vacherin`, `mouche`, `moisi`
(la liste exacte est dans `src/gfx/monster_painter.gd`, table `SIZES`).

### Animations de combat — `data/animations.json`

Chaque attaque de base, compétence et objet utilisable en combat a son animation. Le
moteur (`src/battle/battle_fx.gd`) ne connaît aucune compétence : il lit ce fichier.

**Quelle animation est jouée ?**

- Compétence ou objet : l'animation qui porte **le même identifiant** (`"coup_de_poele"`
  dans `skills.json` joue `"coup_de_poele"` dans `animations.json`). Un champ facultatif
  `"anim": "autre_nom"` dans la compétence ou l'objet permet d'en réutiliser une autre.
- Attaque de base : le champ `"attack_anim"` du bloc `battle` d'un personnage, ou de la
  fiche d'un ennemi.
- Rien de tout cela n'existe : l'animation de repli de l'élément (`attaque_feu`,
  `attaque_tranchant`...), puis `defaut`. Le jeu ne plante donc jamais, mais le test
  automatique signale toute compétence, tout objet ou toute attaque sans animation à soi.

```json
"coup_de_poele": {"pose": "strike", "impact": 0.4, "sound": "swoosh", "pitch": 0.8, "steps": [
	{"fx": "swing", "sprite": "pan", "scale": 2.4, "at": 0.26},
	{"fx": "burst", "sprite": "star", "count": 5, "at": 0.38, "sound": "clang"},
	{"fx": "flash", "color": "#ffffff", "power": 0.2, "at": 0.38},
	{"fx": "shake", "power": 0.8, "at": 0.38}]}
```

- `pose` : ce que fait le lanceur. `strike` (élan, bond et coup), `charge` (course tête
  baissée), `sneak` (disparaît et frappe dans le dos), `stomp` (saut et retombée lourde),
  `spin` (tour sur soi au contact), `cast` (s'élève pour lancer un sort), `throw` (lancer),
  `shoot` (vise, puis recul du tir), `sleep` (bascule en arrière), `eat` (hoche, la bouche
  pleine), `guard` (se ramasse), `shout` (prend son souffle et crie), `none`.
- `impact` : moment, en secondes, où le coup porte ; les chiffres de dégâts apparaissent à
  cet instant. `sound` et `pitch` : son joué au départ.
- `steps` : les effets, chacun daté par `at` (secondes depuis le début). Champs communs :
  `sprite` (dessin), `scale` (taille), `color` (`"#rrggbb"`, ou `"element"` pour la
  couleur de l'élément du coup), `add` (lumineux), `count`, `duration`, `sound`, `pitch`,
  `on` (`targets` chaque cible, par défaut ; `caster` le lanceur ; `center` le milieu du
  groupe visé), `where` (`center`, `top`, `feet`), `each` (décalage entre deux cibles).
- Types d'effets (`fx`) :
  - `projectile` : le sprite part du lanceur vers la cible (`arc` hauteur de la cloche,
    `spin` tours sur lui-même, `from: "sky"` s'il vient du ciel) ;
  - `drop` : tombe sur la cible (`height`, `stay` temps de pose à l'arrivée) ;
  - `swing` : arme brandie en arc de cercle sur la cible (`angle`, négatif pour un revers) ;
  - `burst` : `count` sprites jaillissent autour du point (`radius`, `grow`, `spin`) ;
  - `rise` : `count` sprites montent l'un après l'autre (`height`) : Zzz, cœurs, flèches ;
  - `rain` : `count` sprites pleuvent sur la zone (`spread` largeur, `height`) ;
  - `cloud` : `count` bouffées gonflent et se dissipent (`spread`) ;
  - `ring` : anneau qui s'élargit (`grow`) ;
  - `light` : lueur colorée (`power`) ; `flash` : éclair sur tout l'écran (`power` 0 à 0,8) ;
  - `shake` : secousse de caméra (`power` 0 à 1) ; `sound` : un son seul.
- Sprites disponibles (16 × 16 px, peints dans `src/gfx/fx_painter.gd`, table `KINDS`) :
  `spark`, `flame`, `star`, `bolt`, `leaf`, `zzz`, `note`, `pan`, `ladle`, `knife`,
  `sickle`, `sword`, `arrow`, `axe`, `staff`, `bottle`, `mug`, `smoke`, `bubble`, `drop`,
  `ring`, `slash`, `impact`, `plus`, `shield`, `skull`, `coin`, `pillow`, `feather`,
  `rocket`, `eye`, `bang`, `bowl`, `bread`, `cloud`, `root`, `stinger`, `tusk`, `tongue`,
  `fork`, `pot`, `lid`, `scroll`, `crown`, `heart`, `up`, `down`, `dizzy`, `slime`,
  `spore`, `fang`, `hoof`, `wave`, `finger`, `band`, `mouth`, `dust`, `petard`, `hand`,
  `straw`, `web`, `pix`. Un fichier `assets/sprites/fx/<nom>.png` remplace le dessin.
  Les sprites qui ont un sens (flèche, langue, doigt) sont dessinés pointant vers la droite.
- Sons disponibles (synthétisés dans `src/core/sfx.gd`) : `swoosh`, `clang`, `slash`,
  `thud`, `boom`, `zap`, `fire`, `snore`, `gulp`, `splat`, `buzz`, `whistle`, `twang`,
  `roar`, `croak`, `chime`, `poof`, `yawn`, `coin`, `guard`, `squeak`, `stomp`, `bubble`,
  `pop`, `fanfare`, `shriek`, `munch`, `burp`, `wind`, `rustle`, `bell`, plus ceux de
  l'interface (`hit`, `weak`, `magic`, `heal`, `status`, `break`, `ko`...).
- Réactions communes, réglées ailleurs : dans `elements.json`, `"fx"` et `"sound"` donnent
  l'éclat et le son d'un coup de cet élément ; dans `statuses.json`, `"fx"` est le symbole
  qui s'élève quand l'état est posé (crâne du poison, Zzz du sommeil, bouclier...).
- **Ajouter une compétence** : l'écrire dans `skills.json`, puis écrire dans
  `animations.json` une entrée du même nom en recopiant celle qui ressemble le plus.

### `data/encounters.json`

- `encounters` : rencontres nommées, lancées par un dialogue. `enemies` (liste), `arena`,
  `flee` (faux pour un boss), `boss` (identifiant d'un ennemi de la liste qui domine la scène ;
  `false` : aucun boss), `intro` (phrase d'ouverture), et pour un combat scénarisé :
  `party` (équipe imposée, avec niveaux ; rien n'est alors conservé après le combat),
  `inventory` (objets prêtés), `hints` (conseils affichés tour après tour).
  `ramollissement` impose une valeur ; sinon c'est celle de la carte d'où part le combat.
- Choix de l'arène (`BattleScene.resolve`, appelé par `main.start_battle`) : le champ `arena` de
  la rencontre l'emporte ; sinon celui de la carte d'où part le combat (champ `arena` de
  `data/maps/<carte>.json`, à côté de `music`) ; sinon (ou si l'arène est inconnue) le Pré.
  Si la rencontre n'a pas de `music`, c'est celle de l'arène (champ facultatif `music`).
  Les tables n'ont donc plus d'`arena` : la carte décide.
- `tables` : rencontres aléatoires d'une zone. `min_distance` / `max_distance`
  (distance à parcourir dans la zone avant un combat), `groups` (chacun avec `enemies`,
  `weight`, et au besoin `min_party` / `max_party` selon la taille de l'équipe).

### `data/arenas.json`

Arènes de lieu (chapitres 1 à 3) : `taverne`, `etage_auberge`, `ruelle_nuit`, `cave_fromage`,
`ferme`, `route`, `col`, `cite_elfique`, `salle_conseil`, `archives`, `quai`. Nouveautés de
format utilisées par elles :
- `backdrop.panels` : liste de panneaux peints par code (`src/gfx/arena_panels.gd`, `kind` parmi
  taverne, etage, ruelle, cave, ferme, route, col, cite, conseil, archives, quai), chacun
  `{kind, z (-11,4), w (36), h (6), x, y, dim}` : la lumière est cuite dans l'image, découpe franche.
- `backdrop.steps: []` supprime la paroi en gradins : c'est un intérieur, le mur est un panneau.
- `backdrop.far_w`, `far_y` : largeur et hauteur du panneau lointain (plus étroit = relief plus gros).
- `backdrop.far` accepte aussi `peaks`, `valley`, `hills_church`.
- Sols (`src/gfx/arena_painter.gd`) : `plank_worn`, `plank_dark`, `plank_wet`, `cobble_wet`,
  `cellar_stone`, `farmyard`, `gravel_road`, `snow_rock`, `parquet_paper`. Accessoires de premier
  plan flou : `tankard`, `chair_back`, `bucket`, `cheese_cut`, `paper_stack`, `quill_pot`,
  `milestone`, `thistle`, `candlestick`, `snow_rock`, `marker_pole`, `bedpost`, `coil_rope`, `life_buoy`.
- `particles` : en plus, `snow`, `mist`, `spores`, `paper`. Ambiances ajoutées : `aube`, `col_neige`.

Le décor d'un combat : `ground` (texture du sol), `ambiance` (de `ambiances.json`),
`backdrop` et `features` (voir plus haut), `props` (décors semés par `zone` : `back` derrière les combattants, `mid` autour, `front`
devant, flous), `lights`.

### Dans les cartes

- `{"type": "encounter_zone", "rect": [...], "table": "..."}` : marcher dans ce rectangle
  finit par déclencher une rencontre de la table.
- `{"type": "monster", "id": "ennemi", "pos": [...], "dialogue": "...", "solid": 1.0}` : un
  monstre visible, qui bloque le passage et à qui l'on « parle ».
- Tout objet accepte `"unless": "drapeau"` (absent dès que le drapeau est posé) et
  `"if": "drapeau"` (présent seulement s'il est posé). La carte se reconstruit toute seule
  quand un dialogue change un de ces drapeaux.
- `"gated": true` signale au test automatique qu'un objet n'est atteignable qu'une fois
  un obstacle scénarisé levé.

## Musique — `data/music.json`

Un morceau par identifiant. Tout est calculé par `src/core/music.gd`, sans fichier audio.

```json
"village": {
	"name": "Bittebourg, où tout tient debout",
	"tempo": 104, "echo": 0.2, "reverb": 0.25, "loop": true, "volume": 1.0,
	"voices": [
		{"instrument": "flute", "volume": 0.5, "len": 2, "notes": ["d5 g5 b5:4 a5 g5 d5:4", "..."]},
		{"instrument": "drums", "volume": 0.3, "len": 2, "notes": "k h s h k h s h"}
	]
}
```

- `tempo` : battements par minute. `echo` : force de l'écho (0 à 0.6). `reverb` (facultatif,
  0 à 0.6) : petite salle, quatre reprises très rapprochées qui bouclent comme l'écho.
  `loop` : faux pour un morceau joué une seule fois (fanfare).
- `instrument` : `flute`, `reed`, `pluck`, `bell`, `strings`, `brass`, `bass`, `square`,
  ou `drums`. Ajoutés par la refonte : `whistle` (flûte de bois, tin whistle), `fiddle`
  (violon, vibrato qui s'installe), `harp` (harpe), `horn` (cor), `lowbrass` (trombones),
  `choir` (nappe de chœur, attaque lente), `spic` (cordes piquées pour les ostinatos).
- `notes` : une chaîne, ou une liste de chaînes (une par mesure, plus lisible). Les notes
  sont séparées par des espaces : `c4` (do, octave 4), `f#3`, `bb2` (si bémol), `r`
  (silence), `c4+e4+g4` (accord). L'octave est retenue d'une note à l'autre.
- Durée : `:8` après la note, en pas (un pas = une double croche, seize par mesure à
  quatre temps). Sans cela, la durée est le `len` de la voix.
- Nuance : `@1` à `@9` après la note (`c4:4@8`, `k:2@3`), 6 par défaut (= 1). Elle
  s'applique à la note ou au coup de batterie, par-dessus le `volume` de la voix.
- Batterie : `k` grosse caisse, `s` caisse claire, `h` charleston, et depuis la refonte
  `t` timbale (grave, longue), `b` bodhrán (tambour irlandais), `c` cymbale (longue, en
  crescendo). On peut jouer plusieurs coups ensemble : `t+c:4@9`.
- Mesures asymétriques : le pas reste la double croche ; une mesure de 7/8 compte 14 pas
  (4+4+6), une de 5/4 compte 20 pas, une de 6/8 ou de 3/4 compte 12 pas. Le `tempo` donne
  la durée de quatre pas.
- Une voix plus courte que le morceau se répète ; la durée du morceau doit être un
  multiple de celle de chaque voix.
- Calcul : les notes identiques (même instrument, hauteur, durée) ne sont synthétisées
  qu'une fois, ce qui rend les arpèges et les ostinatos presque gratuits ; un morceau de
  cinquante secondes se calcule en environ une seconde, en tâche de fond.
- Composition : les morceaux de la refonte sont originaux (aucun thème de film ou de
  recueil n'est repris). Ils ont tous au moins deux parties, trois voix jouées et, hors
  fanfare, quarante secondes. `tests/smoke_test.gd` (`_test_music_forms`) le vérifie.

Où les morceaux sont utilisés :

- `data/game.json`, `"music": {"title": ..., "battle": ..., "victory": ...}` : écran-titre,
  combat ordinaire, victoire.
- Carte : `"music": "village"`, et en option `"music_states": [{"if": "condition",
  "music": "fete"}]` (la première condition vraie l'emporte ; mêmes conditions que les
  dialogues).
- Rencontre (`data/encounters.json`) : `"music": "boss"`.
- Dialogue : `{"music": "menace"}` change la musique en cours de scène (`""` = silence).

## Sauvegarde

Plusieurs parties, dans le dossier utilisateur (sur Mac :
`~/Library/Application Support/Godot/app_userdata/Glandoulf le Gris/`), un fichier JSON par
emplacement, nommés d'après `SaveManager.save_path` (`user://sauvegarde.json` par défaut) :

- `sauvegarde_m1.json` à `sauvegarde_m8.json` : 8 emplacements manuels (identifiants `m1`...`m8`),
  choisis par le joueur (menu de pause, « Sauvegarder » / « Charger », ou écran-titre).
- `sauvegarde_a1.json` à `sauvegarde_a3.json` : 3 sauvegardes automatiques tournantes (`a1` est
  la plus récente ; une nouvelle décale a1 vers a2 et a2 vers a3, la plus vieille disparaît).
  Elles sont faites à chaque changement de lieu (`auto_reason` = `lieu`) et juste avant chaque
  combat où la fuite est impossible, boss compris (`auto_reason` = `combat`, avec un
  `battle_token` qui permet à l'écran de défaite de proposer « Revenir avant le combat »).
- Écriture atomique : fichier `.tmp` (ou `.new`) écrit en entier puis renommé. Un fichier
  illisible, qui n'est pas un objet JSON ou dont la carte est inconnue est simplement ignoré
  (l'emplacement apparaît vide).
- L'ancien fichier unique (`save_path` lui-même, sans suffixe) est migré tout seul vers le
  premier emplacement manuel libre dès qu'on lit les sauvegardes ; sa date est conservée.
- Changer `save_path` isole tous les fichiers (les tests mettent un chemin par processus) ;
  `SaveManager.delete_save()` efface tous les emplacements dérivés, `delete_slot(id)` un seul.
- En plus de l'état de la partie, chaque fichier porte `saved_at` (texte lisible) et
  `saved_unix` (tri du plus récent au plus ancien). La liste affiche lieu, chapitre, quête en
  cours (la principale d'abord), niveau moyen de l'équipe, temps de jeu et date, calculés à la
  lecture : aucun index séparé.

Le contenu d'un fichier est
l'état de la partie tel que le décrit `src/core/game_state.gd` : chapitre, drapeaux,
quêtes (en cours ou terminées), équipe et banc (`bench`, les compagnons séparés du groupe au chapitre 5 ; niveau, expérience, PV, mana, équipement et
talents appris de chacun ; équipement par emplacement), inventaire, argent, faiblesses
découvertes, carte, position, orientation, temps de jeu. Une sauvegarde de l'étape 1 reste
lisible, de même qu'une sauvegarde de l'étape 2 : ce qui lui manque est complété, et le
journal de quêtes est reconstitué d'après les drapeaux.

## Réglages du joueur (`user://settings.cfg`)

Écrits par l'écran « Paramètres » (titre ou pause), lus au lancement par l'autoload
`Settings` (`src/core/settings.gd`), appliqués tout de suite. Fichier `ConfigFile`
(texte, rubriques entre crochets), **séparé des sauvegardes**. Sans fichier, ou avec une
valeur inconnue ou un fichier illisible, chaque réglage prend son défaut, qui redonne
exactement le rendu d'origine. Les tests et les captures (`res://tests/...`) ignorent ce
fichier : ils tournent avec les défauts et n'écrivent rien.

| Rubrique | Clé | Valeurs (défaut en gras) |
|---|---|---|
| `[affichage]` | `mode` | **`fenetre`**, `plein_ecran`, `sans_bord` |
| | `taille` | `1280x720`, **`1600x900`**, `1920x1080`, `2560x1440` (mode fenêtre) |
| | `vsync` | **`true`**, `false` |
| | `fps_max` | 30, 60, 120, **0** (sans limite) |
| `[rendu]` | `echelle` | 50, 60, 70, 80, 90, **100** (% de l'échelle de rendu 3D ; l'interface reste nette) |
| | `mise_echelle` | **`bilineaire`**, `plus_proche`, `fsr1`, `fsr2`, `metalfx_spatial`, `metalfx_temporel` (les deux derniers seulement si le Mac les gère) |
| | `nettete` | 0 à 10, défaut **9** (FSR 1 seulement ; 10 = plus net) |
| | `anticrenelage` | `aucun`, `fxaa`, `smaa`, `taa`, **`msaa2`**, `msaa4` (sans effet avec `fsr2` et `metalfx_temporel`, qui lissent eux-mêmes) |
| `[details]` | `qualite` | `basse`, **`moyenne`**, `haute`, `perso` (pilote les clés ci-dessous ; calculée si elles ne correspondent à aucun préréglage) |
| | `ombres` | 0 aucune, 1 basses, **2 moyennes**, 3 hautes (atlas 2048 / 4096 / 8192, finesse du filtre, 2 ou 4 zones pour le soleil) |
| | `flou` | 0 aucun, 1 basse, **2 moyenne**, 3 haute (flou de profondeur) |
| | `halo` | **`true`**, `false` (glow) |
| | `brume` | 0 aucune, 1 légère (brouillard simple), **2 normale** (avec brume volumétrique), 3 fine (volume plus détaillé) |
| | `occlusion` | 0 aucune, 1 basse, **2 moyenne**, 3 haute (SSAO) |
| | `particules` | 0 aucune, 1 réduites (40 %), **2 normales** |
| | `rayons` | **`true`**, `false` (rayons de lumière obliques) |
| `[son]` | `general`, `musique`, `effets` | 0 à 100 par pas de 10, défaut **100** (bus `Master`, `Musique`, `Effets`, créés par code) |
| `[divers]` | `compteur` | `true`, **`false`** (compteur d'images par seconde dans un coin) |

Préréglages de qualité (`Settings.PRESETS`) : *Basse* = ombres 1, flou 1, sans halo, brume 1,
sans occlusion, particules 1, sans rayons ; *Moyenne* = les défauts ; *Haute* = ombres 3,
flou 3, brume 3, occlusion 3.

Pour qu'une scène suive ces réglages, l'objet créé passe par `Settings.apply_environment(env)`,
`apply_camera(attributs)`, `apply_light(lumière)`, `apply_particles(émetteur)` ou
`apply_rays(nœud)` : il est réglé tout de suite, puis suit les changements faits ensuite.

### Bord sud des intérieurs

Toute pièce d'intérieur (hors style nain) prolonge son sol au sud de sa dernière rangée de
plancher, assombri peu à peu : la caméra, qui s'arrête à des bornes fixes, ne montre plus de
bande noire. Purement décoratif, sans champ de données (`MapBuilder._build_interior_apron`).


## Conseils de jeu (`data/tutorials.json`)

Liste `tips` : des encarts qui s'affichent une seule fois, au moment où ils servent, puis se
rangent dans « Aide » du menu de pause. Le moteur est `src/core/tutorial.gd` (autoload `Tutorial`).

| Champ | Rôle |
|---|---|
| `id` | identifiant, unique ; c'est lui qui est enregistré dans la sauvegarde (`tutorials`) |
| `trigger` | événement : `arrive`, `interact_near`, `quest_started`, `equip_item`, `talent_point`, `rest`, `save`, `shop`, `reserve`, `battle_start`, `party_turn`, `weak`, `break`, `ally_down` |
| `mode` | `note` (défaut) : encart en bas à droite, n'interrompt rien ; `pause` : suspend le combat ou la boutique jusqu'à une touche |
| `when` | condition facultative, termes liés par `&` : `turn>=N`, `elan`, `shield`, `ally_down`, `boss`, ou une condition de `GameState.check` |
| `who` | personnage qui explique (identifiant ou liste ; le premier présent dans l'équipe parle) |
| `title`, `text` | titre court (40 signes) et texte (320 signes au plus) ; `{interact}` etc. sont remplacés par la touche |
| `keys` | `[[action, verbe], ...]` : pictogrammes affichés (`move`, `interact`, `cancel`, `menu`, `journal`, `elan`, `choose` ou toute action de `InputMap`) ; clavier ou manette selon la dernière entrée |

Règles : un conseil ne s'affiche qu'une fois par partie ; une sauvegarde sans clé `tutorials`
(ancienne) les compte tous comme vus ; l'option `conseils` (Paramètres, « Conseils de jeu »)
les coupe sans les marquer vus ; « Revoir les conseils » les remet à neuf. Aucun conseil de
combat ne s'affiche en combat automatique, rapide, scripté (prologue) ou à `hints`. Pas de
conseils dans les tests sauf `Tutorial.force_on`.

Rappel de quête (`src/ui/objective_tracker.gd`) : montre la quête principale active et son
étape (premier `steps[].done` non rempli de `data/quests.json`), annonce « Nouvelle quête »,
« Quête mise à jour », « Quête terminée » (l'encart glisse depuis la gauche et s'allume d'un éclat
doré). La touche `journal` (J au clavier, Y à la manette) ouvre le journal de quêtes directement ;
elle est rappelée par le rappel et par le conseil « journal ».
