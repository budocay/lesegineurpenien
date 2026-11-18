# Ambiances de combat : les arènes de tout le jeu

Demande de l'auteur (18 novembre 2026) : *« As-tu pensé à créer des ambiances dans les combats suivant où l'on va se trouver ? »* et *« Faut respecter les environnements comme on a dans l'original du Seigneur des Anneaux. »* Aujourd'hui cinq arènes seulement servent aux 26 rencontres du jeu (`pre`, `bois`, `marais`, `place`, `grand_four`). Ce document liste **toutes** celles qu'il faudrait, du chapitre 1 au chapitre 7, avec ce qu'il faut peindre dans chacune.

Il est écrit pour les agents qui rempliront `data/arenas.json` (format dans `docs/FORMAT_DONNEES.md`, section « Arènes ») et qui brancheront chaque rencontre dans `data/encounters.json`. Rien ici n'est du code ; quand une nouveauté demande un peu de code (une particule, un type de fond), c'est écrit.

## Règles de lecture

- **Identifiant** : minuscules, sans accent, comme les clés de `arenas.json`.
- **Sol** : toujours la **matière du lieu**, lisible d'un coup d'œil, jamais de la terre nue par défaut (c'est la critique de l'auteur sur `soil`). Sols existants : `grass`, `soil`, `basalt`, `cobble`, la série `elf_*`. Les autres sont à créer comme tuiles peintes (marqués *nouveau*).
- **Fond** : le champ `backdrop` (`tile` de paroi, `far` lointain, `sky` dégradé). Lointains existants : `hills`, `forest`, `marsh`, `town`, `cavern`. Les lointains *nouveaux* sont dans `horizon_painter.gd` (code), listés à la fin.
- **Premier plan flou** : le champ `foreground`, des accessoires très gros, très flous, entre la caméra et les héros.
- **Lumière et heure** : l'ambiance (`ambiances.json`) et le bloc `stage` (couleur de la nappe, force). Les ambiances déjà existantes sont réutilisées quand elles conviennent : `auberge_nuit`, `cave_fromage`, `pre_combat`, `crepuscule`, `grand_four_combat`, `sous_bois`, `marais`, `fondue_combe`, `fondue_combe_interieur`, `interieur_chaud`.
- **Particules** : existantes `fireflies`, `pollen`, `leaves`, `dust`, `fire`, `embers`, `smoke` ; *nouvelles* proposées : `snow`, `spores`, `ash`, `flour`, `steam`, `petals`, `sparks`, `gold_leaves`, `mist`.
- **Musique** : un morceau de `data/music.json`. Existants : `brie`, `titre`, `village`, `fete`, `auberge`, `campagne`, `bois`, `marais`, `combat`, `boss`, `menace`, `victoire`. Les morceaux *nouveaux* sont décrits en une phrase.
- **Détail drôle** : un élément du décor, visible sans le chercher, qui fait sourire. Jamais lourd, toujours pris au sérieux par le monde.
- Les décors restent au fond et sur les côtés (zone de jeu dégagée, voir décision 119 du suivi). Les détails drôles vivent donc sur la paroi du fond, sur les côtés extrêmes ou au premier plan flou.
- ★ = **à faire tout de suite** : ces lieux existent déjà dans le jeu (chapitres 1 à 3) et se battent aujourd'hui sur la mauvaise arène.

## Branchement : choisir l'arène par la carte (demande de développement)

La demande de l'auteur dit que l'arène est « choisie par la carte où l'on se trouve ». Proposition : un champ `arena` facultatif sur chaque carte de `data/maps/` ; une table de rencontres le reprend par défaut, et peut le remplacer. Ce document donne pour chaque arène les cartes qu'elle sert.

---

# Arènes existantes (à conserver)

### `pre` : le Pré Couché
Sol `grass`, fond `hills`, crépuscule rose et violet, pollen. Sert : Pré Couché, Bittebourg (alentours), Grande Baveuse. À conserver. Détail drôle à ajouter : une bitte d'amarrage couchée dans l'herbe, sans raison.

### `bois` : le Bois Penché
Sol `soil` (à remplacer par un sol de feuilles et de racines : **mousse et feuilles mortes**, *nouveau*), fond `forest`. Sert : Bois Penché, Vieux Solitaire. À repeindre : tous les troncs penchent du même côté, c'est le détail drôle.

### `marais` : la Roselière
Sol `soil` boueux (à remplacer par **vase et planches pourries**), fond `marsh`, mares de `swamp`. Sert : Roselière, Monseigneur. À conserver.

### `place` : la place de village
Sol `cobble`, fond `town`. Sert : place de Bittebourg, le Naze du chapitre 1, et **aujourd'hui, à tort** : le Gardien des Archives, les Nazes de nuit, les duels de bras de fer, les Morfales de l'auberge et du potager. À conserver pour Bittebourg ; les autres rencontres partent vers leur arène propre (ci-dessous).

### `grand_four` : le sommet de la Montagne du Festin
Sol `basalt`, fond `cavern`, mares de lave. Sert : prologue, et **boss final du chapitre 7** (deux phases : voir `arena_oeil` plus bas). À conserver.

---

# Chapitre 1 et 2 : Bittebourg et Brie

### `taverne` ★ (fait)
- **Lieux et rencontres :** Au Bon Mouillage (`morfales_auberge`), le Poney Flagada (`duel_gaston`, `duel_veuve`), et plus tard toute salle commune d'auberge.
- **Sol :** parquet de **planches larges, usées, collantes de bière**, avec des traces de pas et de chopes (*nouveau* : `plank_worn`).
- **Fond :** paroi de **poutres et de torchis**, grande cheminée à droite, bar au fond avec ses tonneaux ; fenêtres à petits carreaux, nuit dehors ; `tile` poutres (*nouveau*), `far` : aucun (intérieur).
- **Premier plan flou :** une chope géante, le dossier d'une chaise, la silhouette floue d'un client qui ne se lève pas.
- **Lumière et heure :** soir ; ambiance `interieur_chaud` ; nappe orange du feu, chaleur des lanternes, ombres longues.
- **Particules :** `smoke` (de la cheminée), `dust` dans les rais de lumière.
- **Musique :** `auberge` (morceau existant) pour les duels ; `combat` pour les Morfales.
- **Détail drôle :** une table couchée sur le flanc, la nappe encore posée dessus, **le dessus de plat gardé au chaud** par le bois d'un barman qui n'a pas bougé.

### `etage_auberge` ★ (fait)
- **Lieux et rencontres :** étage du Poney Flagada (`nazes_nuit`, le boss de deux Nazes de nuit).
- **Sol :** **plancher de bois sombre** grinçant, couloir étroit, tapis élimé au milieu (*nouveau* : `plank_dark`, `rug_worn`).
- **Fond :** couloir de chambres, **portes numérotées** ouvertes sur le noir, une fenêtre au bout par laquelle on voit la lune et un morceau de **rampe d'escalier qui a quitté le bâtiment** (clin d'œil du dialogue de Barnabé).
- **Premier plan flou :** un bout de lit, un pied de lit, un chandelier.
- **Lumière et heure :** pleine nuit ; ambiance `auberge_nuit` ; une lune bleue par la fenêtre, un halo froid autour des Nazes (leur souffle ramollit les bougies : les flammes **penchent**).
- **Particules :** `dust`, une légère buée froide au sol (`mist`).
- **Musique :** `menace` pour l'approche, `boss` au combat.
- **Détail drôle :** sur chaque porte, une affichette « Prière de ne pas déranger le sommeil des voyageurs, ni celui des Nazes ».

### `ruelle_nuit` ★ (fait)
- **Lieux et rencontres :** les rues de Brie la nuit (rencontres de rue après la nuit du Poney, et `naze` si le combat sort dans la rue).
- **Sol :** **pavés mouillés** reflétant les lanternes (`cobble` avec reflets, *nouveau* : `cobble_wet`).
- **Fond :** façades à colombages penchées, volets clos, enseignes de fromagers qui pendent ; ruelle étroite fermée par un mur de brique ; `far` : toits de Brie (`town` nocturne).
- **Premier plan flou :** un tonneau, un tas de caisses de fromage, une charrette.
- **Lumière et heure :** nuit, ambiance `auberge_nuit` ; nappe bleu froid au centre, deux lanternes jaunes en haut des murs.
- **Particules :** `mist`, quelques lucioles de lanterne.
- **Musique :** `brie` ralenti ou `menace`.
- **Détail drôle :** une enseigne de fromager porte la mention « Fromages de caractère » sur un camembert qui s'est écoulé.

### `cave_fromage` ★ (fait)
- **Lieux et rencontres :** les caves de Persillé (`caves_brie`, `vacherin`), la fromagerie.
- **Sol :** **dalle de calcaire humide** et clayettes de bois au bord (*nouveau* : `cellar_stone`).
- **Fond :** voûte de pierre, **rayonnages de meules** à perte de vue, tonneaux de saumure ; `tile` pierre moussue ; `far` : galeries (`cavern`).
- **Premier plan flou :** une meule coupée, un fromage à pâte persillée, une louche géante.
- **Lumière et heure :** sans heure ; ambiance `cave_fromage` ; nappe verdâtre, taches de moisissure bleue qui luisent.
- **Particules :** `spores`, `dust`.
- **Musique :** `marais` ou un morceau de cave (*nouveau* : `cave`, pizzicati de cordes pincées sur un bourdon, un peu humide).
- **Détail drôle :** chaque meule porte une étiquette « Affinage : à l'ancienne, très lent ». Le Vacherin est dessiné en train de **couler vers les étiquettes** comme s'il les relisait.

### `ferme` ★ (fait)
- **Lieux et rencontres :** la ferme Pinard / ferme de Brie (`ferme_brie`, `chantecler`).
- **Sol :** **paille et terre battue mêlées** : un sol de **cour de ferme** avec de la paille, des flaques et des plumes (*nouveau* : `farmyard`).
- **Fond :** grange en bois, abreuvoir, **meule de foin**, poulailler ; `far` : champs de colza (`hills` avec toiture de ferme).
- **Premier plan flou :** un seau, une botte de paille, un sabot de cheval.
- **Lumière et heure :** matin, ambiance `crepuscule` retournée en `aube` (*nouveau* : nappe or pâle) ; le coq a la meilleure place.
- **Particules :** `dust`, `leaves`, une plume qui tourne.
- **Musique :** `campagne`, puis `boss`.
- **Détail drôle :** au fond, une girouette en forme de coq, tournée vers le mauvais côté : Chantecler la regarde avec insistance.

### `route` ★ (fait)
- **Lieux et rencontres :** la route de Brie (`route_brie`, `morfales_route`), toute route de campagne.
- **Sol :** **chemin de gravier et d'ornières** avec une bande d'herbe au milieu, **jamais** de terre nue (*nouveau* : `gravel_road`).
- **Fond :** talus bordés de haies, **borne kilométrique**, barrière brisée ; `far` : collines et un clocher (`hills`).
- **Premier plan flou :** une borne, une touffe d'orties, un chardon.
- **Lumière et heure :** fin d'après-midi, ambiance `pre_combat` ; poussière dorée sur la route.
- **Particules :** `dust`, `pollen`.
- **Musique :** `campagne` (existant) ou `combat`.
- **Détail drôle :** une borne indique « Brie : 2 jours. Bittebourg : 2 jours aussi, mais dans l'autre sens ».

### `quai`
- **Lieux et rencontres :** le quai de Bittebourg (`morfales_quai`), le ponton.
- **Sol :** **planches mouillées**, avec une corde roulée (*nouveau* : `plank_wet`).
- **Fond :** bittes d'amarrage inclinées, barques, filets, la Grande Bitte qui penche ; `far` : eau et saules (`marsh` allégé).
- **Premier plan flou :** une bitte, un cordage, une bouée.
- **Lumière et heure :** crépuscule, `crepuscule` ; reflets orange sur l'eau.
- **Particules :** `pollen`, `mist` légère.
- **Musique :** `village` avec `combat`.
- **Détail drôle :** plusieurs bittes penchent, **toutes du même côté**, et une porte une plaque « Fierté du village, ne pas toucher ».

*(Le potager de Pépin, `morfales_potager`, peut rester sur `place` ; s'il devient un lieu à part : sol de planches de potager, poireaux flétris au fond, cloche à melon renversée au premier plan.)*

---

# Chapitre 3 : Fondue-Combe

### `col` ★ (fait)
- **Lieux et rencontres :** le col des Biscottes (`col_biscottes` : chamois, marmottes, taons), puis le départ de Fondue-Combe.
- **Sol :** **neige tassée et roche** (*nouveau* : `snow_rock`, un sol blanc-bleu par plaques, glace dessous).
- **Fond :** parois de granit, sapins noirs, pic enneigé ; `far` : sommets (*nouveau* : `peaks`) ; ciel d'altitude bleu froid.
- **Premier plan flou :** un rocher givré, une touffe d'herbe sèche, un poteau de **balisage** penché.
- **Lumière et heure :** midi clair, ombres longues ; ambiance `fondue_combe` plus froide ; nappe blanche.
- **Particules :** `snow`, `mist`.
- **Musique :** un morceau de col (*nouveau* : `col`, cor lointain et pas lent de timbales).
- **Détail drôle :** une pancarte « Altitude 1 800 m. Départ des biscottes. À consommer sur place » devant un chamois qui la regarde de haut.

### `cite_elfique` ★ (fait)
- **Lieux et rencontres :** Fondue-Combe, la ville des Elfes (`fondue_combe`).
- **Sol :** `elf_flag` (dallage ivoire), bordure de pelouse `elf_lawn`.
- **Fond :** terrasses de pierre claire, arcs brisés, cascades, toits bleu-gris ; `tile` : `elf_terrace` ; `far` : vallée et cascade (*nouveau* : `valley`).
- **Premier plan flou :** une colonne cannelée, un vase de lierre, un banc de pierre.
- **Lumière et heure :** matin doré, `fondue_combe` ; bleu clair et or.
- **Particules :** `petals` (fleurs d'arbres d'or), `mist` de cascade.
- **Musique :** un morceau elfique (*nouveau* : `elfes`, harpe et flûte, très lent, un peu en retard sur lui-même).
- **Détail drôle :** une fontaine porte la plaque « Prière de ne pas se presser. Les eaux n'ont pas hâte ».

### `salle_conseil` ★ (fait)
- **Lieux et rencontres :** Salle du Conseil, Chancellerie (les rencontres de couloir ; aucune pour l'instant).
- **Sol :** `elf_parquet` (parquet pâle), un long tapis gris.
- **Fond :** **longue table** d'orme vide, fauteuils, vitraux à fond de lierre ; `tile` : `elf_wall_vista`.
- **Premier plan flou :** une plume géante, un encrier, une pile de feuillets.
- **Lumière et heure :** matin, `fondue_combe_interieur`, rais de lumière par les vitraux.
- **Particules :** `dust` doré.
- **Musique :** `elfes` ou `menace`.
- **Détail drôle :** l'ordre du jour est cloué au mur : « 8. (voir 6.) ». Un huissier pétrifié continue à noter.

### `archives` ★ (fait)
- **Lieux et rencontres :** Archives du Conseil (`archives`, `gardien_archives`).
- **Sol :** **parquet ciré** couvert de feuillets tombés (*nouveau* : `parquet_paper`).
- **Fond :** rayonnages jusqu'au plafond, échelles à roulettes, **registres** reliés de cuir ; `tile` : `elf_wall_books`.
- **Premier plan flou :** une pile de formulaires, un tampon géant, une lampe à huile.
- **Lumière et heure :** sans heure ; `fondue_combe_interieur` assombri, halos des lampes.
- **Particules :** `dust`, **feuilles de papier** qui voltigent (*nouveau* : `paper`).
- **Musique :** `menace` ; `boss` pour le Gardien.
- **Détail drôle :** une pancarte « Silence, ordre, respect. Il est interdit de lire. » et, sous elle, un lecteur silencieux et très penché.

---

# Chapitre 4 : la route des monts et les Mines de Morbier

### `route_monts`
- **Lieux et rencontres :** sentier de montagne avant Morbier (Ouargues-Garous, Troll Raclette).
- **Sol :** **éboulis et cailloux** (*nouveau* : `scree`), traces de neige qui fond.
- **Fond :** pentes ravinées, sapins tordus, dalle de granit barrée d'un vieux **portique de péage** brisé ; `far` : sommets.
- **Premier plan flou :** un gros caillou, un cairn de randonneur, une botte de bruyère sèche.
- **Lumière et heure :** crépuscule froid, ciel orange sur violet.
- **Particules :** `mist`, `snow` rare.
- **Musique :** `col`, puis `combat`.
- **Détail drôle :** un panneau de bois « Pas de loups. Pas ce soir. » et, juste dessous, des traces de pattes.

### `porte_morbier`
- **Lieux et rencontres :** le lac devant la porte de Morbier (Guetteur du lac, boss).
- **Sol :** **berge de galets noirs et dalles taillées** s'enfonçant dans l'eau (*nouveau* : `shore_pebble`).
- **Fond :** falaise nue ; **deux battants de pierre** gravés d'un vieux dessin, le lac noir, des tentacules qui dépassent ; `far` : falaise (`cavern`).
- **Premier plan flou :** une épave de barque, un roseau, une main de pierre.
- **Lumière et heure :** nuit de lune ; froide, argentée ; l'œil du Guetteur jaune dans l'eau.
- **Particules :** `mist`, bulles.
- **Musique :** `menace` puis `boss`.
- **Détail drôle :** au-dessus de la porte, en lettres naines : « Dites ami et entrez ». Dessous, à la craie : « (ou autre chose, nous ne sommes pas sectaires) ».

### `galeries`
- **Lieux et rencontres :** galeries de Morbier (Gobelardons).
- **Sol :** **rail de wagonnet et ballast** (*nouveau* : `mine_rail`), une ligne de cendre au milieu (la **ligne de cendre** de Morbier).
- **Fond :** tunnel étayé de **poutres de mine**, lanternes de mineur, wagonnets renversés ; `tile` pierre sombre.
- **Premier plan flou :** un pic, un wagonnet vu de côté, une lanterne.
- **Lumière et heure :** sans heure ; torches orange, `cave_fromage` réchauffé ; nappe orange, fond brun.
- **Particules :** `dust`, `embers`.
- **Musique :** `mines` (*nouveau* : cuivres graves sur un bourdon, enclume lointaine).
- **Détail drôle :** une pancarte « Jours sans accident : 0. Jours sans grève : 0. »

### `salle_piliers`
- **Lieux et rencontres :** la Grande Salle (« les cent piliers ») de Morbier, rencontres de grande salle.
- **Sol :** **dallage noir et veines de cendre** (`basalt` clair, *nouveau* : `basalt_ash`).
- **Fond :** **cent piliers** qui se perdent dans le noir, voûte lointaine, braseros ; `far` : profondeur (`cavern`).
- **Premier plan flou :** un pilier tronçonné, un casque de nain posé.
- **Lumière et heure :** sans heure ; lueur rouge des braseros, bleu d'ombre.
- **Particules :** `embers`, `dust`.
- **Musique :** `mines`.
- **Détail drôle :** chaque pilier porte, gravé, le nom d'un nain et la mention « excusé ».

### `chambre_comptes`
- **Lieux et rencontres :** la chambre des comptes de Morbier (Troll Affineur).
- **Sol :** **dalles de pierre** et tas de **papiers calcinés** (`flagstone`, *nouveau*).
- **Fond :** un sarcophage de pierre, des **tablettes de comptes** murales, des **fromages entassés** (le troll en est l'affineur) ; `tile` : pierre sombre.
- **Premier plan flou :** une meule, un crochet de boucher, un seau de saumure.
- **Lumière et heure :** sans heure ; lueur verte d'un trou de lumière, bleu froid.
- **Particules :** `dust`.
- **Musique :** `boss`.
- **Détail drôle :** sur le sarcophage : « Ci-gît le chef de la colonie. Ne pas déranger : il est en grève ».

### `pont_morbier`
- **Lieux et rencontres :** le pont de Morbier (Le Balourd, deux phases).
- **Sol :** **dalle de pierre étroite sans parapet**, fendue, au-dessus du vide (`bridge_stone`, *nouveau*).
- **Fond :** gouffre de feu, escarpements, pont qui se continue sur le noir ; `far` : gouffre (`cavern` rouge) ; **mares de lave** (`features` : `pool` lave).
- **Premier plan flou :** une arche brisée, des braises, un morceau de rambarde.
- **Lumière et heure :** sans heure ; lueur rouge-orange montant du vide ; ambiance `grand_four_combat`.
- **Particules :** `embers`, `fire`.
- **Musique :** `boss`, avec un choc de cuivres graves.
- **Détail drôle :** un panneau d'avertissement : « Pont étroit. Un seul à la fois. Ne pas courir. Ne pas être le Balourd. »

### `lac_souterrain`
- **Lieux et rencontres :** la caverne de Goulûm (duel d'énigmes et combat).
- **Sol :** **galets mouillés et sable noir** au bord de l'eau (`cave_beach`, *nouveau*).
- **Fond :** lac souterrain, îlot, stalactites ; `far` : eau noire.
- **Premier plan flou :** une canne sans hameçon, un filet suspendu, un petit poisson blanc.
- **Lumière et heure :** sans heure ; lumière pâle de l'eau, reflets de l'anneau en haut de l'îlot.
- **Particules :** `mist`.
- **Musique :** `marais` ralenti.
- **Détail drôle :** un chevalet de pêche, une flèche indique « Plus gros poisson du monde : par ici. Ne pas toucher. »

---

# Interlude : la Lothlorraine

### `lothlorraine`
- **Lieux et rencontres :** les bois dorés de Lothlorraine (l'interlude entre les chapitres 4 et 5).
- **Sol :** **tapis de feuilles d'or** sur de la mousse fine (`gold_moss`, *nouveau*).
- **Fond :** futaie d'arbres aux feuilles d'or qui ne tombent pas, plateformes rondes en tourtière dans les branches, escaliers en spirale ; `far` : forêt d'or (*nouveau* : `golden_forest`).
- **Premier plan flou :** une feuille d'or géante, une lanterne de verre, un tronc blanc.
- **Lumière et heure :** matin sans fin ; lumière dorée, rais verticaux ; ambiance `fondue_combe` réchauffée.
- **Particules :** `gold_leaves`, `pollen` d'or.
- **Musique :** `lothlorraine` (*nouveau* : chœur très doux, harpe).
- **Détail drôle :** des tourtières suspendues, avec la mention « Ici, tout est rond, et tout se partage ».

### `miroir`
- **Lieux et rencontres :** la clairière du Miroir (Reflets).
- **Sol :** **dalle de pierre ronde** d'un bassin, avec un pourtour d'herbe fine.
- **Fond :** un grand bassin d'eau noire, arbres d'or autour, brume basse ; `far` : forêt d'or.
- **Premier plan flou :** une branche, la margelle du bassin.
- **Lumière et heure :** aube argentée, lueur du miroir.
- **Particules :** `mist`, `fireflies`.
- **Musique :** `lothlorraine` ralenti.
- **Détail drôle :** une plaque : « Le Miroir ne montre pas ce qui sera. Il montre ce que vous en feriez. »

---

# Chapitre 5 : le Roquefort et l'Isengarde-Manger

### `chutes_gratin`
- **Lieux et rencontres :** le camp au-dessus des chutes (embuscade des Ouroukouilles).
- **Sol :** **berge d'herbe humide et de galets**, bord de fleuve (`riverbank`, *nouveau*).
- **Fond :** chute d'eau dorée comme une croûte de gratin, rocher, rive opposée en brume ; `far` : chute (*nouveau* : `falls`).
- **Premier plan flou :** une barque de croûte retournée, un roseau, un galet.
- **Lumière et heure :** couchant ; ambiance `pre_combat` ; reflets sur l'eau.
- **Particules :** `mist` d'eau, `leaves`.
- **Musique :** `menace` puis `combat`.
- **Détail drôle :** une barque « en croûte de miche » à moitié mangée par la berge.

### `plaine_roquefort`
- **Lieux et rencontres :** les plaines du Roquefort (Ouargues-Garous, Hirsutes de Dunlande, Uglouk).
- **Sol :** **herbe haute à épis et tapis de trèfle** (`tall_grass`, *nouveau*, pas de terre).
- **Fond :** collines basses à l'infini, **meules**, quelques brebis, un fort à fanion ; `far` : plaine (*nouveau* : `plain`) ; ciel immense.
- **Premier plan flou :** épis de blé, un piquet de clôture, une touffe de trèfle.
- **Lumière et heure :** aube ou crépuscule venteux ; ambiance `pre_combat`, chaude et dorée.
- **Particules :** `pollen`, `leaves` couchées par le vent.
- **Musique :** `plaine` (*nouveau* : cor, cordes en galop, un thème libre et large).
- **Détail drôle :** au fond, **des brebis broutent en rang serré** : l'état-major des Cavaliers regarde la bataille sans bouger.

### `fongorn`
- **Lieux et rencontres :** la forêt de Fongorn (Hors-d'œuvres égarés, Entremets, rencontre de Glandoulf).
- **Sol :** **mousse épaisse et racines** couvertes de lichen (`moss_deep`, *nouveau*).
- **Fond :** troncs géants, **visages dans l'écorce**, lianes ; `far` : forêt profonde ; `tile` écorce.
- **Premier plan flou :** une racine énorme, une fougère géante, un champignon.
- **Lumière et heure :** matin brumeux ; ambiance `sous_bois` ; colonnes de lumière verte et ambre.
- **Particules :** `spores`, `mist`, `leaves`.
- **Musique :** `fongorn` (*nouveau* : basses de bois, un souffle lent).
- **Détail drôle :** un arbre porte un panonceau « Réunion en cours. Revenir dans trois jours ».

### `bergerie_or`
- **Lieux et rencontres :** la Bergerie d'Or de Cabécou (Grimace Langue-de-Bois).
- **Sol :** **planches de chêne polies**, dalles incrustées de laiton (`oak_boards`, *nouveau*).
- **Fond :** **grande salle en bois doré**, poteaux sculptés de **brebis cabrées**, trône sous un dais, foyer central ; `tile` bois sculpté.
- **Premier plan flou :** un pilier sculpté, un banc, un crochet de laine.
- **Lumière et heure :** jour d'hiver, rais dorés des fenêtres hautes ; ambiance `interieur_chaud` plus clair.
- **Particules :** `dust` doré, `smoke` du foyer.
- **Musique :** `plaine` en version intérieure.
- **Détail drôle :** au mur, un tapis **tissé de laine véritable**, avec la devise « Qui ne dort pas ne règne pas » : Théodort ronfle dessous.

### `petrins`
- **Lieux et rencontres :** le cercle de l'Isengarde-Manger (Ouroukouilles, Pâtons, Uglouk) : les fosses où la pâte lève.
- **Sol :** **dalles de fonte noire** striées de **farine et de charbon** (`cast_iron`, *nouveau*).
- **Fond :** mur circulaire de pierre noire, **cheminées d'usine**, pétrins gigantesques, tour noire au centre ; `far` : fumées et tour (*nouveau* : `ironworks`).
- **Premier plan flou :** un rouleau à pâtisserie géant, une palette à enfourner, un sac de farine.
- **Lumière et heure :** nuit de forge ; rouge des fours ; ambiance `grand_four_combat` plus sèche.
- **Particules :** `flour` (poussière blanche en suspension), `embers`. **Mécanique :** un sort de feu dans cette arène provoque une *explosion de farine* (dégâts en zone aux deux camps).
- **Musique :** `isengarde` (*nouveau* : forge, percussions de tôle, ostinato mécanique).
- **Détail drôle :** une pancarte « Rendement du mois : excellent. Rendement du mois prochain : meilleur ».

### `garde_manger`
- **Lieux et rencontres :** la cellule des Grobittes (combat contre Froton Anneauté).
- **Sol :** **dalles de pierre froide** et paille (`stone_cell`, *nouveau*).
- **Fond :** un mur de **cages à jambon** avec crochets de boucher, étiquettes « À conserver » ; une lucarne ; `tile` pierre noire.
- **Premier plan flou :** un crochet de boucher, un bocal, un cadenas.
- **Lumière et heure :** nuit ; lueur dorée de l'anneau qui éclaire tout, très chaud ; contraste avec le fond bleu.
- **Particules :** `embers` dorées, `dust`.
- **Musique :** `menace` puis `boss` (un thème du Serrage, cordes graves).
- **Détail drôle :** les cages portent chacune une fiche « Pièce fermière, affinage en cours : Grobitte ».

### `terrasse_office`
- **Lieux et rencontres :** le sommet de la tour de l'Office (Sarumâle, boss).
- **Sol :** **dalle de basalte** striée de cercles dorés (`basalt_gold`, *nouveau*).
- **Fond :** vue sur le cercle d'Isengarde inondé, fumées noires qui se dissipent, arbres en marche ; `far` : cercle d'Isengarde (*nouveau*).
- **Premier plan flou :** un balustre brisé, une cheminée, la Mirette sur son socle.
- **Lumière et heure :** aube après la bataille ; or pâle, rose, brume ; la robe blanche prend tout.
- **Particules :** `mist`, `ash`.
- **Musique :** `boss` (le grand thème d'Isengarde en version cuivres).
- **Détail drôle :** un **tableau de service** accroché à la balustrade, avec les plannings de la semaine, tous raturés.

---

# Chapitre 6 : Minas Tartine

### `minas_remparts`
- **Lieux et rencontres :** la Grande Porte et le premier niveau, la Croûte (Gothmoque, Grondine, Morfales de siège).
- **Sol :** **pierre blanche, chemin de ronde**, taches de goudron (`white_stone`, *nouveau*).
- **Fond :** **rempart blanc**, créneaux, tours de guet, étendards, le **Mont Croûton** derrière ; `far` : ville et plaine (*nouveau* : `white_city`).
- **Premier plan flou :** un créneau, une échelle, un baril d'huile.
- **Lumière et heure :** nuit de siège, rougeoiement des incendies, lune pâle ; ambiance `crepuscule` assombri.
- **Particules :** `embers`, `smoke`.
- **Musique :** `minas` (*nouveau* : cuivres blancs, choral de chœur, pulsation de timbales).
- **Détail drôle :** sur le créneau, une plaque « Plus dure sera la chute », avec une échelle appuyée dessus.

### `minas_rues`
- **Lieux et rencontres :** niveaux 2 à 5 (Morfales de siège, sapeurs, Cassoulétains).
- **Sol :** **pavés blancs** en escaliers, gouttières.
- **Fond :** rues en lacets, maisons blanches à toits d'ardoise, arcades ; `far` : ville en gradins.
- **Premier plan flou :** une marche, une lanterne, une fontaine.
- **Lumière et heure :** aube trouble ; fumées ; ambiance `crepuscule`.
- **Particules :** `smoke`, `embers`.
- **Musique :** `minas`.
- **Détail drôle :** des écriteaux « Niveau 3 : Beurre. Niveau 4 : Confiture. Pas de tartine sans niveaux ».

### `citadelle`
- **Lieux et rencontres :** la cour du Poirier Blanc (septième niveau), les Maisons de guérison.
- **Sol :** **dalles de marbre blanc**, veines grises, un cercle de pierre sombre au pied de l'arbre mort (`marble_white`, *nouveau*).
- **Fond :** **Tour du Goûter** blanche, Poirier Blanc mort ou malade, escaliers, ciel d'orage ; `far` : ville en contrebas.
- **Premier plan flou :** un banc, une statue de roi, une urne.
- **Lumière et heure :** aube, rose et blanc, les premiers rais ; ambiance `fondue_combe` plus froide.
- **Particules :** `petals` qui ne tombent pas, `mist`.
- **Musique :** `minas`, ralenti.
- **Détail drôle :** le Poirier Blanc penche, un tuteur de noisetier le soutient ; une plaque : « Soutien provisoire, depuis 1 200 ans ».

### `pelle_a_tarte`
- **Lieux et rencontres :** champs du Pelle-à-Tarte (Mammous, Cassoulétains, Éveillés, Naze Suprême).
- **Sol :** **herbe foulée et piétinée**, ornières, fumée au ras du sol (`battlefield`, *nouveau* : herbe foulée, pas de terre).
- **Fond :** la **cité blanche** au loin, bannières, **trébuchets** en flammes, fumée ; `far` : ville en fond ; ciel d'aube rouge.
- **Premier plan flou :** une lance plantée, une bannière déchirée, un casque.
- **Lumière et heure :** aube ; rouge et or ; ambiance `crepuscule` renversée en aurore.
- **Particules :** `smoke`, `embers`, `ash`.
- **Musique :** `bataille` (*nouveau* : grand thème de bataille, cors, tambour).
- **Détail drôle :** un trébuchet a été chargé d'un **fromage de belle taille** ; le panneau « Bonne chute ».

### `sentier_insomniaques`
- **Lieux et rencontres :** le sentier sous la montagne (Éveillés, Roi des Éveillés).
- **Sol :** **dalle de pierre humide** couverte de **traces de pas** par milliers (`dead_path`, *nouveau*).
- **Fond :** galerie noire, **statues de dormeurs**, lits de pierre au mur, squelettes en pyjama ; `far` : cavité (`cavern`).
- **Premier plan flou :** un lit défait de pierre, un oreiller, un bonnet de nuit.
- **Lumière et heure :** sans heure ; **vert fantôme**, bleu froid ; ambiance `cave_fromage` retournée.
- **Particules :** `mist` verte, **cendres** blanches qui tombent comme de la neige.
- **Musique :** `eveilles` (*nouveau* : chœur soupiré, un bourdon qui ne s'arrête pas).
- **Détail drôle :** des lits de pierre alignés, **tous faits**.

### `port_sale`
- **Lieux et rencontres :** le port fluvial (Boucaniers d'Ombrine, capitaine Saumure).
- **Sol :** **quai de pierre et de planches** couvert de sel et de filets.
- **Fond :** navires aux **voiles de torchon noir**, grues de bois, entrepôts à poissons ; `far` : fleuve et mâts.
- **Premier plan flou :** un tonneau, un cordage, un hareng sur un crochet.
- **Lumière et heure :** matinée grise ; vent.
- **Particules :** `mist`, `smoke`.
- **Musique :** `combat` (variante marine, *nouveau* : accordéon et tambour).
- **Détail drôle :** le drapeau pirate est une **tête de poisson sur deux pelles croisées**.

---

# Chapitre 7 : le Mordgras

### `marais_bouillon`
- **Lieux et rencontres :** le marais des morts (Noyés du Bouillon, feux follets).
- **Sol :** **planches noyées et vase grise** avec des plaques de brume verte (`dead_marsh`, *nouveau*).
- **Fond :** étendue d'eau stagnante, **visages sous la surface**, pointes d'arbres morts ; `far` : marais lointain avec un feu de fumée.
- **Premier plan flou :** une branche morte, un roseau, un visage qui affleure.
- **Lumière et heure :** crépuscule éternel ; vert-de-gris, **un ciel sans soleil**.
- **Particules :** `mist` verte, `fireflies` pâles.
- **Musique :** `marais` en version sourde ; `marais_morts` (*nouveau* : cordes basses).
- **Détail drôle :** un écriteau planté dans la vase : « Baignade interdite. Quoique. »

### `passe_plat`
- **Lieux et rencontres :** la plaine devant la Porte Noire, le **Passe-Plat** (Bouche du Maître, Ologrills, Cassoulétains, Mammous).
- **Sol :** **cendre grise veinée de bleu moisi** (`ash_plain`, *nouveau*).
- **Fond :** **porte noire gigantesque** à guichet horizontal, un passe-plat de fer, tours d'angle, dents de pierre ; `far` : remparts.
- **Premier plan flou :** un piquet, un casque, un morceau de chaîne.
- **Lumière et heure :** midi sans soleil ; rouge sale ; l'Œil au loin.
- **Particules :** `ash`, `embers`.
- **Musique :** `mordgras` (*nouveau* : cuivres graves, percussions de casseroles).
- **Détail drôle :** sur la porte, une grande plaque : « Livraisons : voir guichet. Il n'y a pas de guichet. »

### `gorgonzola`
- **Lieux et rencontres :** la plaine de cendres au pied de la montagne.
- **Sol :** **cendre grise parcourue de veines vert-bleu** (comme un fromage moisi), terre craquelée (`ash_veined`, *nouveau*).
- **Fond :** plaine de cendre, tour noire au loin avec un œil, montagne de feu ; `far` : tour et montagne (*nouveau* : `mordgras_far`).
- **Premier plan flou :** une pierre ponce, un tas de cendre, un casque de Morfale.
- **Lumière et heure :** crépuscule rouge sans fin.
- **Particules :** `ash`, `sparks`.
- **Musique :** `mordgras`.
- **Détail drôle :** des **veines bleues** dans le sol, que les Morfales appellent « le persillé ».

### `col_arachnee`
- **Lieux et rencontres :** le col et la grotte de l'Arachnée (Fileuses, Arachnée).
- **Sol :** **roche couverte de fils de soie épais** (`web_floor`, *nouveau*).
- **Fond :** tunnel noir tapissé de **toiles**, cocons suspendus, escaliers sans fin ; `far` : trou noir.
- **Premier plan flou :** un fil tendu, un cocon, une patte.
- **Lumière et heure :** sans heure ; lueur de la fiole ; bleu nuit.
- **Particules :** `dust`, fils qui flottent (`silk`, *nouveau*).
- **Musique :** `arachnee` (*nouveau* : cordes grattées, ostinato nerveux).
- **Détail drôle :** un petit **bonnet de dentelle** accroché à un fil, et un ouvrage de tricot inachevé.

### `cuisines`
- **Lieux et rencontres :** les cuisines de la Tour de la Barbaque (Morfales plongeurs et sauciers, un Naze Sommelier).
- **Sol :** **carrelage noir et blanc, gras et glissant** (`kitchen_tile`, *nouveau*).
- **Fond :** **fourneaux monumentaux**, marmites de six mètres, broches, files de plats qui passent ; `far` : voûte de cuisine.
- **Premier plan flou :** une louche géante, un entonnoir, un sac de sel.
- **Lumière et heure :** sans heure ; flammes, vapeur.
- **Particules :** `steam`, `smoke`, `sparks`.
- **Musique :** `cuisines` (*nouveau* : percussions de casseroles, valse infernale en 7 temps).
- **Détail drôle :** une pancarte : « Cuisine : interdit aux cuisiniers. Service : interdit au service ».

### `salle_banquet`
- **Lieux et rencontres :** la Salle du Banquet perpétuel (Convives Insatiables, brigade des Nazes du Service).
- **Sol :** **parquet d'ébène ciré** couvert de miettes et de sauces (`ebony_floor`, *nouveau*).
- **Fond :** **table infinie**, lustres de fer, convives de dos, plats qui passent ; `far` : voûte.
- **Premier plan flou :** une carafe, un chandelier, une assiette énorme.
- **Lumière et heure :** sans heure ; chandelles ; ambiance `auberge_nuit` réchauffée, dorée sale.
- **Particules :** `smoke`, `dust`, `steam`.
- **Musique :** `banquet` (*nouveau* : valse lente et fatiguée, un air qu'on ne peut pas arrêter).
- **Détail drôle :** un convive **s'est endormi dans son assiette** : le seul de la salle.

### `escalier`
- **Lieux et rencontres :** les Quatre Mille Marches (Marcheurs Infatigables, rencontres de palier).
- **Sol :** **marches de pierre usées**, creusées par les pas (`stair_stone`, *nouveau*).
- **Fond :** paroi de roche, lave dans le vide ; l'Œil derrière la montagne ; `far` : ciel de cendre.
- **Premier plan flou :** une rambarde de corde, une marche brisée.
- **Lumière et heure :** rougeoyant sans fin ; plus on monte, plus c'est clair.
- **Particules :** `embers`, `ash`.
- **Musique :** `escalier` (*nouveau* : ostinato de pas lents, un cor au loin).
- **Détail drôle :** une marche sur cent porte un panneau « Courage » ; sur la dernière, « Encore un peu ».

### `arena_oeil` (variante du Grand Four)
- **Lieux et rencontres :** phase 1 du boss final, avant que Sauron ne redevienne un corps.
- **Sol :** `basalt` avec un cercle d'or, comme l'anneau.
- **Fond :** l'**Œil**, de flamme, au milieu d'un cercle de braise qui tourne comme une broche ; `far` : fente rouge.
- **Premier plan flou :** une cendre, un flocon d'or.
- **Lumière et heure :** rouge et or ; le sol est éclairé par l'Œil.
- **Particules :** `embers`, `ash`.
- **Musique :** `boss` final, thème de la Vigueur.
- **Détail drôle :** le coin du fond porte une assiette où quelqu'un a laissé un dessert intact.

---

## Récapitulatif

| Priorité | Arènes |
|---|---|
| **★ Faites** (chapitres 1 à 3, choisies par la carte : champ `arena`) ; `quai` aussi | `taverne`, `etage_auberge`, `ruelle_nuit`, `cave_fromage`, `ferme`, `route`, `col`, `cite_elfique`, `salle_conseil`, `archives` ; puis `quai` |
| Pour le chapitre 4 | `route_monts`, `porte_morbier`, `galeries`, `salle_piliers`, `chambre_comptes`, `pont_morbier`, `lac_souterrain`, `lothlorraine`, `miroir` |
| Pour le chapitre 5 | `chutes_gratin`, `plaine_roquefort`, `fongorn`, `bergerie_or`, `petrins`, `garde_manger`, `terrasse_office` |
| Pour le chapitre 6 | `minas_remparts`, `minas_rues`, `citadelle`, `pelle_a_tarte`, `sentier_insomniaques`, `port_sale` |
| Pour le chapitre 7 | `marais_bouillon`, `passe_plat`, `gorgonzola`, `col_arachnee`, `cuisines`, `salle_banquet`, `escalier`, `arena_oeil` |

**Nouveautés qui demandent du code** (un peu, côté `horizon_painter.gd` et le semis de particules) : lointains `peaks`, `valley`, `golden_forest`, `falls`, `plain`, `ironworks`, `white_city`, `mordgras_far` ; particules `snow`, `spores`, `ash`, `flour`, `steam`, `petals`, `sparks`, `gold_leaves`, `mist`, `paper`, `silk` ; sols peints listés ci-dessus ; mécanique de l'explosion de farine des `petrins`.

**Musique** : les nouveaux morceaux à composer sont `cave`, `col`, `elfes`, `mines`, `lothlorraine`, `plaine`, `fongorn`, `isengarde`, `minas`, `bataille`, `eveilles`, `mordgras`, `marais_morts`, `arachnee`, `cuisines`, `banquet`, `escalier`. Rappel : la durée d'un morceau doit être un multiple de la durée de chaque voix (piège connu du suivi).
