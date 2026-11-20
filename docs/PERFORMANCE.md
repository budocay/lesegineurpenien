# Fluidité : chargements, préchauffage, caches

But : aucun gel visible. Tout ce qui est lourd se passe sous le fondu noir, devant un écran de
chargement qui reste animé (un arc doré qui tourne, `src/ui/loading_spinner.gd`).

## D'où venait le gel

Mesure (fenêtre, vsync coupé, Mac M1 Max, première entrée sur une carte) : 85 à 100 % du temps
d'une première entrée était de la PEINTURE D'IMAGES PAR CODE sur le fil principal (planche de
chaque personnage de la carte, sol complet de la carte, monstres), pas de la compilation de
shaders. Les shaders et pipelines coûtent au plus quelques dizaines de millisecondes sur Metal
(la pire image visible, hors fondu noir, restait sous 25 ms) ; le risque est plus grand sous
Windows (Direct3D 12), non mesuré.

## Ce qui est fait

- **Construction étalée** : `World.setup(..., staged=true)` et `MapBuilder.build` rendent la main au
  moteur (une image) dès qu'une étape dépasse 20 ms (`MapBuilder._due`). Pendant ce temps le monde est en
  `PROCESS_MODE_DISABLED` (`Main._load_world`) et le fondu reste noir ; l'arc de chargement tourne. Sans
  `staged` (tests, captures), tout est synchrone comme avant. La carte du titre se construit d'un seul tenant.
- **Cache disque du sol** (`user://cache_decor/`) : `Sprites.disk_load / disk_store`, appelés par
  `MapBuilder._paint_ground`. Clé = carte, taille, cases, données de la carte ; préfixe = empreinte
  (`Sprites.decor_stamp`) du texte de tous les peintres de `src/gfx`, de `map_builder.gd` et des tuiles
  remplacées dans `assets/sprites/tiles` : toute retouche d'un peintre repeint, et les anciens fichiers sont
  effacés tout seuls. Un sol coûte de 0,1 à 1 s à peindre, quelques millisecondes à relire.
- **Planches de personnages** : fil d'arrière-plan `Sprites._warm_characters` qui remplit
  `user://cache_persos/` pendant le titre et le début de partie (le peintre de personnages n'a qu'un état :
  `_char_mutex`). Écriture atomique (fichier provisoire puis renommé).
- **Préchauffage des shaders** (`src/gfx/prewarm.gd`) : au lancement, sous un écran noir « Chargement… »
  animé, un SubViewport hors champ dessine une fois chaque shader du dossier `src/gfx/shaders` sur un maillage
  éclairé qui projette des ombres (0,2 à 0,6 s), puis six ambiances types (environnement, glow, brouillard,
  rayons, particules). Cette seconde phase n'a lieu qu'à partir du deuxième lancement sur la machine (fichier
  `user://cache_prewarm.txt`, empreinte = moteur + pilote + carte graphique) : au tout premier lancement le
  cache de shaders de Godot est vide, les ambiances coûtaient alors plus de 10 s de compilation que la carte du
  titre paie de toute façon (lancement vierge mesuré : 28 s avec, 11 s sans). `GLAN_PREWARM_FULL=1` la force.
  La liste des shaders est LUE dans le dossier avec `ResourceLoader.list_directory` (et non `DirAccess`, qui
  ne voit pas les fichiers sous leur nom d'origine dans un jeu exporté ; vérifié sur un paquet exporté : 19
  shaders listés et chargés) : un nouveau shader dans `src/gfx/shaders` est préchauffé sans rien faire, et le
  test automatique échoue si un `.gdshader` de `src` est hors de ce dossier. `GLAN_NO_PREWARM=1` coupe tout.
- **Fils d'arrière-plan** (`Sprites.start_background`, appelé par `Main` une fois le titre affiché) : personnages,
  monstres, puis monstres gouda et boss (ces derniers avec le peintre d'origine, sous `_mon_mutex`, que le fil
  principal prend aussi s'il en a besoin). Ils ne partent plus au démarrage du processus : sur un lancement
  vierge ils volaient du temps de calcul (lancement vierge +5 s).
- **Fermeture** : `Music` attend ses tâches de calcul en cours (`_exit_tree`, les tâches en attente s'arrêtent
  aussitôt) ; avant, `--quit-after` pendant le premier calcul des morceaux plantait (signal 11, aussi sur
  la version d'avant). Les fils de `Sprites` sont joints à la fermeture.
- **Combat** : « Chargement… » et l'arc s'affichent pendant la construction de l'arène, sous le fondu.
- `near_start` vaut 0,70 par défaut dans `world.gd` quand la carte ne le déclare pas.

## Mesurer

```bash
# en fenêtre, tableau par carte et par combat (première entrée « froid », seconde « chaud »)
GLAN_ONLY_PERF=1 Godot --path . res://tests/smoke_test.tscn
# vrai froid : un autre HOME (caches vides) ; créer d'abord « Library/Application Support/Godot/app_userdata/<nom du jeu> »
# dans ce HOME (sinon Godot n'y cache aucun shader). Lancer deux fois : la première est « vierge », la seconde « habituelle ».
HOME=/tmp/perfhome GLAN_ONLY_PERF=1 Godot --path . res://tests/smoke_test.tscn
```

Variables : `GLAN_PERF_MAPS=a,b` (cartes), `GLAN_PERF_OUT=fichier.json`, `GLAN_PERF_LOG=1` (les clés les
plus longues à peindre après chaque carte, les phases du préchauffage), `GLAN_PERF_IDLE=s` (attente sous le
titre avant les mesures, pour laisser les fils remplir les caches), `GLAN_PERF_NOSTRESS=1` (saute les essais de
robustesse : deux changements de carte enchaînés, combat pendant un chargement, chargement de sauvegarde).
Colonnes : `total` (fondus fixes de 0,8 s compris), `noir` (temps sous le noir complet : le vrai coût),
`pire` (pire image de tout le changement), `visible` (pire image hors noir complet), `builder` / `horiz`
(script de construction, horizon), `peint` (peinture d'images, inclus dans `builder`), `reste` (joueur, PNJ,
caméra). La ligne « Lancement » donne l'instant où l'écran-titre est prêt. Sur un Mac chargé par d'autres
programmes les chiffres bougent de 20 à 30 % : refaire une mesure suspecte.

## Limites connues

- **Caches disque vides** (tout premier lancement, ou après la retouche d'un peintre de `src/gfx` : l'empreinte
  change et tout est repeint) : le travail de peinture existe toujours. Un personnage coûte 0,5 s, un sol de
  0,1 à 1,5 s, un gros monstre peint par `gouda_monsters.gd` / `boss_painter.gd` jusqu'à 7 s d'un seul bloc
  (le peintre ne se découpe pas). Les fils d'arrière-plan préparent tout cela pendant le titre et le jeu, et
  s'arrêtent pendant les chargements (`Sprites.bg_pause`) ; mais une carte visitée très tôt peut encore coûter
  de 1 à 8 s sous le noir (Minas Tartine, Port-Saumure : les monstres gouda), avec l'arc figé pendant le bloc
  le plus long. Une fois les caches remplis, plus rien de tout cela.
- Le sol, peint d'un seul tenant (`_paint_ground`), n'est pas étalé : l'arc s'arrête pendant ce calcul à
  la première visite après une retouche.
- Premier lancement sur une machine neuve : la compilation des shaders du moteur (10 s sur ce Mac, sans
  rapport avec ce travail) a lieu sous l'écran de chargement ; elle est payée une seule fois.
- Les shaders ne sont préchauffés que dans les variantes de ce SubViewport ; une combinaison de lumières
  ou d'ombres inédite peut encore se compiler à la volée (non mesuré sous Windows / Direct3D 12).
- Sur Metal, la compilation de shaders ne coûtait déjà presque rien une fois le cache de Godot rempli : le gain
  mesuré vient de la peinture (caches disque), pas du préchauffage. Le préchauffage vise surtout Windows.
