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
  animé (environ 0,25 s), un SubViewport hors champ dessine une fois chaque shader du dossier
  `src/gfx/shaders` sur un maillage éclairé qui projette des ombres, puis six ambiances types
  (environnement, glow, brouillard, rayons, particules). La liste des shaders est LUE dans le dossier avec
  `ResourceLoader.list_directory` (et non `DirAccess`, qui ne voit pas les fichiers sous leur nom d'origine
  dans un jeu exporté) : un nouveau shader dans `src/gfx/shaders` est préchauffé sans rien faire, et le test
  automatique échoue si un `.gdshader` de `src` est hors de ce dossier. `GLAN_NO_PREWARM=1` le coupe (essais).
- **Combat** : « Chargement… » et l'arc s'affichent pendant la construction de l'arène, sous le fondu.
- `near_start` vaut 0,70 par défaut dans `world.gd` quand la carte ne le déclare pas.

## Mesurer

```bash
# en fenêtre, tableau par carte et par combat (première entrée « froid », seconde « chaud »)
GLAN_ONLY_PERF=1 Godot --path . res://tests/smoke_test.tscn
# vrai froid (caches disque vides) : un autre HOME, pour ne pas toucher aux sauvegardes
HOME=/tmp/perfhome GLAN_ONLY_PERF=1 Godot --path . res://tests/smoke_test.tscn
```

Variables : `GLAN_PERF_MAPS=a,b` (cartes), `GLAN_PERF_OUT=fichier.json`, `GLAN_PERF_LOG=1` (les clés les
plus longues à peindre après chaque carte). Colonnes : `total` (fondus fixes de 0,8 s compris), `noir`
(temps sous le noir complet : le vrai coût), `pire` (pire image de tout le changement), `visible` (pire image
hors noir complet), `builder` / `horiz` (script de construction, horizon), `peint` (peinture d'images, inclus
dans `builder`), `reste` (joueur, PNJ, caméra).

## Limites connues

- Première partie sur une machine neuve (aucun cache disque) : un personnage coûte 0,5 s à peindre, un
  gros monstre peint par `gouda_monsters.gd` / `boss_painter.gd` plusieurs secondes (ils passent par l'état
  statique du peintre d'origine, donc sur le fil principal). Le fil d'arrière-plan les prépare en jouant,
  mais une carte visitée très tôt peut rester longue une fois. Chaque retouche d'un peintre refait ce chemin.
- Le sol, peint d'un seul tenant (`_paint_ground`), n'est pas étalé : l'arc s'arrête pendant ce calcul à
  la première visite après une retouche.
- Les shaders ne sont préchauffés que dans les variantes de ce SubViewport ; une combinaison de lumières
  ou d'ombres inédite peut encore se compiler à la volée (non mesuré sous Windows).
