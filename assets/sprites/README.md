# Remplacer les images du jeu

Toutes les images du jeu sont dessinées par le code. Pour en remplacer une par une vraie
image, il suffit de déposer un fichier PNG au bon endroit avec le bon nom : le jeu le prend
à la place du dessin généré. Si le fichier est absent, le dessin généré revient tout seul.
Rien d'autre n'est à modifier.

Tout passe par un seul script, `src/gfx/sprite_library.gd`.

Les images sont affichées sans lissage (pixels nets). Fond transparent obligatoire pour les
personnages et les décors.

## Personnages — `characters/<identifiant>.png`

L'identifiant est celui du fichier `data/characters.json` (`glandoulf`, `sam`, `fripon`,
`pepine`, `gedeon`, `titou`, `meme_louchette`, `anselme`, `berthe`, `odilon`).

Les planches peintes par le jeu font 352 × 192 pixels : 11 colonnes (repos, respiration,
clignement ; quatre poses de marche ; attaque, sort, coup reçu, KO). Une planche déposée
ici peut être plus simple.

Format par défaut d'une planche déposée, 128 × 192 pixels :

- cases de **32 × 48 pixels** ;
- **4 colonnes**, dans cet ordre : immobile, premier pas, passage (jambes réunies),
  second pas ;
- **4 lignes**, dans cet ordre : vers le bas (face), vers la gauche, vers la droite, vers
  le haut (dos) ;
- les pieds posés à **2 pixels** du bas de la case, le personnage centré dans la largeur ;
- 24 pixels valent une case du décor : un Grobitte fait environ 30 pixels de haut,
  Glandoulf environ 44.

Pour une planche d'un autre format, ajouter à côté un fichier `characters/<identifiant>.json` ;
toutes les clés sont facultatives :

```json
{
	"columns": 4,
	"rows": ["down", "left", "right", "up"],
	"walk": [1, 2, 3, 0],
	"idle": 0,
	"pixels_per_unit": 24,
	"foot_margin": 2,
	"fps": 7
}
```

Trois clés de plus pour une planche plus riche : `"idle_seq": [0, 0, 1, 1, 0, 2]` (colonnes
jouées à l'arrêt, à `idle_fps` images par seconde, 4 par défaut) et
`"poses": {"attack": 7, "cast": 8, "hit": 9, "ko": 10}` (colonnes des poses de combat ; une
pose absente garde simplement le dessin de repos).

Les valeurs ci-dessus sont celles prises par défaut. `walk` donne les numéros de colonnes à
enchaîner pendant la marche, `idle` la colonne affichée à l'arrêt, `foot_margin` le nombre
de pixels vides sous les pieds. La taille des cases se déduit de la taille de l'image, du
nombre de colonnes et du nombre de lignes.

## Monstres — `monsters/<type>.png`

Types actuels : `limace`, `baveuse`, `guepe`, `champignon`, `epouvantail`.

- Une seule rangée de poses côte à côte (deux par défaut), jouées en boucle. Les monstres
  peints par le jeu en ont quatre : repos, respiration, attaque, coup reçu. Pour une image
  déposée qui en a autant, ajouter au `.json` : `"columns": 4, "idle": [0, 1],
  "poses": {"attack": 2, "hit": 3}`.
- Le monstre regarde **vers la droite** (vers l'équipe), pieds en bas de l'image.
- Fond transparent, pas de lissage.
- Un fichier `monsters/<type>.json` facultatif précise le découpage :
  `{"columns": 2, "pixels_per_unit": 32, "foot_margin": 1}` (`columns` : nombre de poses ;
  `pixels_per_unit` : pixels par unité de monde ; `foot_margin` : pixels vides sous les pieds).
- Sauron et Isidur sont des personnages : ils suivent le format `characters/`.

## Portraits — `portraits/<identifiant>.png`

Image carrée affichée dans la boîte de dialogue (conseillé : 48 × 48 pixels, elle est
agrandie sans lissage). Sans fichier, le portrait est peint : la tête de face, agrandie deux
fois avec lissage des diagonales. Il sert dans les dialogues, le menu Équipe, le choix d'une
cible d'objet, l'écran de talents et la file des tours en combat.

## Décors — `props/<type>.png` ou `props/<type>_<variante>.png`

Types existants : `tree`, `bush`, `flowers`, `grass`, `wheat`, `wilted`, `barrel`, `sign`,
`rock`, `bollard`, `monument`, `boat`, `shelf`, `window`. La variante est un numéro à partir
de 0 (par exemple `tree_0.png` à `tree_3.png`). L'objet est posé sur le sol par le bas de
l'image, centré ; 24 pixels valent une case.

## Textures — `tiles/<type>.png`

Carreaux de 48 × 48 pixels qui se répètent (une texture couvre deux cases de côté) :
`grass`, `path`, `cobble`, `planks`, `floor`, `wood`, `soil`, `plaster`, `brick`, `stone`,
`iron`, `roof_rouge`, `roof_vert`, `roof_ardoise`, `roof_chaume`. Exception :
`interior_wall` fait 48 × 72 pixels (un mur de trois cases de haut).
