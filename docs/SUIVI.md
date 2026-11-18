# Suivi du projet — Glandoulf le Gris

Ce fichier est le journal de bord du projet. Il dit où en est le jeu, quelles décisions ont
été prises sans pouvoir poser la question, et ce qui reste à faire. Il est à relire au début
de chaque nouvelle session de travail et à mettre à jour à la fin.

## État actuel

**Étape 1 (le socle) : terminée.** En appuyant sur F5 on obtient :

- un écran-titre (Nouvelle partie, Continuer, Quitter) posé sur une vue du village ;
- Glandoulf, animé dans les quatre directions, qui se promène dans Bittebourg au crépuscule
  (maisons, arbres, buissons, lanternes, chemins, quai, barques, champ) ;
- collisions, caméra qui suit, bâtiments de premier plan qui s'estompent ;
- rendu HD-2D : monde en 3D, personnages en pixel art, flou de profondeur, lumières
  chaudes, ombres, halo lumineux, brume, lucioles ;
- neuf Grobittes à qui parler, plus des panneaux, des portes et des bittes à examiner ;
- un intérieur, l'auberge « Au Bon Mouillage », où l'on entre par la porte ;
- sauvegarde automatique à chaque changement de lieu, sauvegarde manuelle dans le menu
  de pause ou auprès de Berthe l'aubergiste, reprise avec « Continuer ».

**Étape 2 (les combats au tour par tour) : terminée.** S'y ajoutent :

- un **prologue jouable** : « Nouvelle partie » s'ouvre trois cents ans plus tôt, devant le
  Grand Four. Glandoulf et le roi Isidur (niveau 20, tous leurs sorts) affrontent Sauron
  dans un combat-tutoriel : six conseils s'affichent, un par tour ;
- le **système de combat complet** : ordre des tours selon la vitesse (file affichée en
  haut à gauche), Attaquer, Compétences (mana), Objets, Défendre, Fuir ; huit états
  (poison, sommeil, sonné, ramolli, englué, galvanisé, garde, ébranlé) ; six éléments ;
  faiblesses à découvrir et bouclier à briser ; expérience, niveaux, compétences apprises
  en montant de niveau ; argent et butin ; écran de victoire ; écran de défaite
  (« Recommencer le combat » ou « Retour à l'écran-titre ») ;
- un **écran de combat HD-2D** : arène en 3D (pré au crépuscule, ou Grand Four rougeoyant),
  sprites en pixel art, flou de profondeur, lumières, particules, chiffres de dégâts ;
- une nouvelle carte, **le Pré Couché**, à l'est de Bittebourg (sortir par la route de
  l'est) : la route est sûre, les champs de blé couché déclenchent des rencontres
  (limaces molles, guêpes à cidre, champignons dormeurs, épouvantails avachis) ;
- un mini-boss, **la Grande Baveuse**, qui dort en travers de l'entrée d'un enclos ; la
  vaincre donne accès à trois racines-qui-réveillent ;
- **Pépine rejoint l'équipe** si on lui parle une deuxième fois devant son potager ;
- se **reposer chez Berthe** (auberge) rend tous les PV et le mana ;
- le menu de pause affiche l'équipe (niveau, PV, mana), l'argent et l'inventaire.

**Étape 4 (quêtes, inventaire, boutiques) : terminée.** S'y ajoutent :

- un **journal de quêtes** (menu de pause, « Quêtes ») : les quêtes démarrent et
  s'achèvent toutes seules selon ce que fait le joueur, un message l'annonce en haut à
  droite, et le journal montre l'étape en cours et les étapes déjà faites ;
- **cinq quêtes à Bittebourg** : « Ce qui ramollit le Comté » (fil rouge du chapitre),
  « Le potager en deuil » (Pépine), « La poêle des Gamelle » (Sam), « Un héritage très
  récent » (la pipe, Fripon) et une annexe, « Sauver les apparences » (caler les bittes
  du port pour Maître Gédéon : elles se redressent à l'écran) ;
- les **vraies scènes de recrutement** : Sam rejoint l'équipe quand on lui rapporte sa
  poêle (rachetée 40 écus à la marchande), Fripon quand on revient le voir avec Sam ; il
  rend alors la pipe de Glandoulf. L'équipe peut donc compter quatre membres ;
- l'**équipement** : trois emplacements par personnage (arme, tenue, babiole), dix objets
  à porter, des bonus visibles dans la fiche du personnage et pris en compte en combat ;
- un **écran d'équipe** (statistiques, expérience, équipement, compétences) et un
  **inventaire** d'où l'on peut boire une tisane ou un cidre hors combat et s'équiper ;
- l'**argent** (les écus) sert enfin : **l'étal d'Ursule**, sur le quai de Bittebourg,
  vend remèdes et équipement et rachète à moitié prix ;
- le **Ramollissement en mécanique de jeu** : sur une carte touchée (témoin rose en haut
  à gauche), tous les coups physiques, ceux des ennemis comme ceux de l'équipe, portent
  moins fort (10 % à Bittebourg, 25 % au Pré Couché). La magie n'est pas touchée. On y
  échappe avec le tuteur en noisetier (récompense de Pépine) ou un petit remontant.

**Étape 5 (le chapitre 1 complet) : terminée.** Le chapitre se joue du prologue à la
route de Brie. S'y ajoutent :

- trois **nouvelles zones** autour de Bittebourg : le **Bois Penché** (sortie nord du
  village), la **Roselière** (sortie sud-est) et la **route de Brie** (barrière de
  l'ouest, fermée jusqu'à la fin de l'histoire du village) ; chacune a ses rencontres,
  ses coffres, son arène de combat et son ambiance ;
- **huit nouvelles créatures** (frelon des bois, amanite molle, sanglier flapi, grenouille
  bouffie, sangsue des roseaux, feu follet, Morfale éclaireur, Morfale goinfre) et
  **trois boss** : le Vieux Solitaire (bois), Monseigneur le crapaud-buffle (roselière)
  et **le Naze**, boss du chapitre, qui change de tactique à mi-combat ;
- **quatre quêtes annexes** : « L'omelette de la Saint-Cabestan » (cèpes du bois, œufs
  de cane de l'îlot, jury de Mémé Louchette), « Le bouquet promis » (trois pierres de
  soufre pour les fusées de Titou), « La course de barques » (avec Nestor, en trois
  décisions) et « Avis de battue » (le Vieux Solitaire, pour Anselme) ;
- la **Fête des Amarres** : quand l'équipe est au complet et le potager soigné, Berthe
  propose de dormir jusqu'à la Fête. Le village se pare de tables et de lampions, Ursule
  reçoit de nouveaux articles, les annexes se concluent ;
- la **cérémonie** (l'estrade, sur la place) : la Grande Bitte se couche, le Naze et ses
  Morfales entrent dans le village. Il faut chasser trois groupes de Morfales (quai,
  potager, auberge), puis affronter le Naze au pied de la Grande Bitte ;
- la **révélation** (l'anneau, le pêcheur Trempette, Morbier) puis la **route de Brie** :
  un feu de camp, un péage de Morfales, et en haut de la dernière butte la **fin du
  chapitre 1**, avec sauvegarde. Le Comté reste ouvert ensuite ;
- trois nouvelles compétences (niveaux 6 et 7), douze objets et pièces d'équipement.

**Durée.** En comptant les dialogues, les trois zones, les quatre annexes et une
trentaine de combats, le chapitre demande à mon estimation de quarante à soixante
minutes ; en ligne droite, sans annexes, autour de vingt-cinq à trente. Cette durée
n'a pas été chronométrée par un joueur.

**Étape 3 (spécialisations et talents) : terminée.** Les règles et les données des
talents avaient été écrites en rattrapage après les étapes 4 et 5, mais l'écran était une
simple liste à cases « [x] » enfouie sous « Équipe », que personne n'avait jamais vue : pour
le joueur, l'étape n'existait pas. La session du 18 novembre 2026 l'a reprise : vérification
de l'existant, noms définitifs, et un **vrai écran de talents** (voir plus bas). On a donc :

- des **points de talent** : un par niveau gagné. L'écran de victoire l'annonce, le menu
  de pause et l'écran d'équipe rappellent les points qui restent à dépenser ;
- les **deux voies de chacun des sept personnages de la bible** (Glandoulf, Sam, Fripon,
  Pépine, et déjà Aragrogne, Légolasse et Gimlette pour les chapitres suivants) : quatre
  talents par voie, cinquante-six en tout, à apprendre dans l'ordre. Les deux premiers
  coûtent un point, les deux suivants deux : six points pour une voie entière ;
- un **écran de talents** dédié (`src/ui/talent_screen.gd`) : menu de pause, « Talents »
  (le bouton annonce les points à dépenser). Un onglet par membre de l'équipe avec son
  portrait, ses deux voies côte à côte, quatre talents reliés de haut en bas, colorés selon
  leur état (doré : appris ; bleu : on peut l'apprendre ; gris : fermé), le détail du talent
  sous le curseur à droite, et « Tout oublier » qui rend les points gratuitement. On y
  arrive aussi par « Équipe », fiche d'un personnage, « Talents » ;
- un **rappel après un combat** qui fait gagner des points (message en haut à droite), et
  la ligne de l'écran de victoire qui dit où aller ;
- des talents qui **changent vraiment les combats** : vingt-six nouvelles compétences
  (Pétarade, Viens-y voir, Fauche, Brouillard épais...), des bonus de statistiques, et des
  effets permanents (riposte, coups critiques, vol d'écus, récupération de PV ou de mana,
  soins plus forts, états plus sûrs, départ en avance) ; trois nouveaux états
  (Provocateur, Démoralisé, Enfumé) ;
- l'**intégration au chapitre 1** : une recrue arrive avec les points de son niveau ; le
  Naze a été renforcé pour rester un vrai boss face à une équipe qui a ses talents.

**Animations de combat (priorité 2 de l'auteur, 18 novembre 2026) : terminées.**

- Chaque attaque de base (8 héros, 17 ennemis), chacune des 74 compétences et chacun des
  7 objets utilisables en combat a **son animation à elle** : 107 animations dans
  `data/animations.json`, jouées par `src/battle/battle_fx.gd`, qui ne connaît aucune
  compétence.
- **Douze poses** du lanceur (`strike`, `charge`, `sneak`, `stomp`, `spin`, `cast`,
  `throw`, `shoot`, `sleep`, `eat`, `guard`, `shout`) : élan et bond jusqu'au contact,
  course tête baissée, passage dans le dos, saut et retombée, incantation, lancer, tir...
- **Douze types d'effets** (projectile, chute, arme brandie, gerbe, montée, pluie, nuage,
  anneau, lueur, éclair d'écran, secousse, son) et **62 petits sprites d'effets** peints
  par code (`src/gfx/fx_painter.gd`) : poêle, louche, fusée, oreiller, Zzz, éclair,
  flèche, hache, bol, chope, parchemin, langue, dard, sabot...
- **Coup reçu** : éclair blanc, recul et bascule en arrière, plus marqués sur une faiblesse
  ou un critique (avec éclair d'écran) ; éclat et son propres à l'élément du coup.
  **KO** : un allié chancelle puis s'effondre, un ennemi sursaute puis s'aplatit dans un
  nuage de poussière. **Retour** : l'allié se relève d'un bond, plumes.
- États, soins, mana, garde, coup raté, vol : chacun a son symbole (crâne, Zzz, bouclier,
  croix vertes, gouttes bleues...) et son bruit.
- **31 nouveaux sons** synthétisés (souffle filtré et trémolo ajoutés au générateur).
- Une compétence future sans animation prend celle de son élément, puis `defaut` : le jeu
  ne plante pas, et le test automatique la signale.

**Pixel art (priorité 3 de l'auteur, 18 novembre 2026) : terminé.**

- **Personnages repeints** (`src/gfx/character_painter.gd`, entièrement réécrit) : planche
  de 11 poses par direction au lieu de 4. Repos animé (respiration, clignement des yeux),
  **quatre poses de marche** distinctes (appui, passage, appui, passage, avec balancement
  des bras et déhanchement), et **quatre poses de combat dessinées** : attaque (bras levé,
  sourcils froncés), sort (bras tendus, yeux fermés), coup reçu (bras en l'air, yeux
  plissés, dents serrées), KO (affaissé).
- Visages lisibles : yeux avec reflet, sourcils, joues, bouche qui change selon la pose ;
  oreilles pointues, pieds nus poilus des Grobittes, ombres et lumières sur chaque pièce.
- **Morfales et Naze ont leur propre corps** (champ `species` du `look`) : brutes voûtées
  à défenses et gros poings, le goinfre en tablier et toque ; spectre sans jambes à cape
  en lambeaux, capuche vide aux yeux qui luisent, couronne de fer et lame pâle.
- **Monstres** : quatre poses au lieu de deux (repos, respiration, **attaque** gueule
  ouverte, **coup reçu** yeux plissés) et une passe de volume (bord clair, bord sombre).
- Le combat utilise ces dessins : pose d'attaque ou de sort pendant l'action, coup reçu,
  KO, pour les héros comme pour les ennemis.
- **Portraits** peints (tête de face agrandie et lissée, 48 × 48) : dialogues, écran de
  talents, file des tours, et désormais menu Équipe et choix de la cible d'un objet.
- **Décors plus riches** : brins, trèfles et fleurs dans l'herbe ; ornières et gravier
  sur les chemins ; fêlures, reflets et mousse sur les pavés et les murs ; nœuds et clous
  sur les planches ; mottes et pousses dans la terre ; lézardes dans l'enduit.
- Captures d'avant conservées dans `docs/captures/avant_pixel_art/` pour comparer.

## Commandes

| Action | Clavier | Manette |
|---|---|---|
| Se déplacer | Flèches, ou ZQSD (WASD sur clavier QWERTY) | Croix ou stick gauche |
| Parler, examiner, valider | Entrée, Espace ou E | A |
| Annuler, revenir | Retour arrière ou X | B |
| Menu de pause | Échap, Tab ou M | Start |
| Plein écran | F11 ou F | — |

En combat : flèches (ou ZQSD) pour parcourir le menu et changer de cible, Entrée / Espace /
E pour valider, Retour arrière ou X pour revenir en arrière. La souris marche aussi sur les
boutons.

## Comment vérifier que tout marche

Deux outils sont rangés dans `tests/`. Ils se lancent depuis un terminal ouvert dans le
dossier du projet.

- **Test automatique** (sans fenêtre, environ cinq minutes) :
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/smoke_test.tscn`
  Il doit finir par `RESULTAT : OK`. Il contrôle les données, les sprites, la construction
  des cartes, le fait que chaque personnage et chaque porte soient atteignables à pied,
  tous les dialogues, la sauvegarde, et un déroulé complet (titre, nouvelle partie,
  déplacement, entrée dans l'auberge, dialogue, sauvegarde, Continuer, sortie).
  Depuis l'étape 2 il contrôle aussi les règles du combat (dégâts, mana, faiblesses,
  bouclier, états, objets, niveaux, victoire, défaite, fuite), l'équilibre (360 combats
  simulés), l'écran de combat piloté par ses menus, puis le prologue, une rencontre dans
  les champs et le combat contre la Grande Baveuse joués en entier dans le vrai jeu.
  Mettre `GLAN_QUICK=1` devant la commande s'arrête après les règles et l'équilibre
  (quelques secondes).
  Depuis l'étape 4 il contrôle aussi les quêtes (départ, étapes, récompense donnée une
  seule fois), l'équipement, les objets hors combat, les achats et les ventes, le
  Ramollissement, les quatre écrans de menu pilotés ligne par ligne, puis, dans le vrai
  jeu, la quête du potager jusqu'à sa récompense, un achat chez Ursule et les écrans
  ouverts depuis la pause.
  Depuis l'étape 3 il contrôle aussi les talents : les données des cinquante-six talents,
  les points gagnés et dépensés, l'ordre dans une voie, l'oubli, la sauvegarde, chaque
  effet en combat (riposte, provocation, vol, brouillard...), chaque compétence de talent
  lancée une fois, treize combats simulés de plus avec les talents dépensés dans l'une ou
  l'autre voie, et l'écran de talents lui-même : ouverture, curseur, apprentissage, refus,
  changement de personnage, oubli, les sept arbres de la bible appris en entier depuis
  l'écran, puis l'ouverture depuis la pause et depuis la fiche d'un personnage dans le
  vrai jeu.
  Ajouter `-- --verbose` affiche en plus les cartes et quelques sprites en caractères.
- **Captures d'écran** (ouvre une fenêtre pendant environ deux minutes, ne pas
  toucher au clavier pendant ce temps) :
  `/Applications/Godot.app/Contents/MacOS/Godot --path . res://tests/capture.tscn -- "$PWD/docs/captures"`
  Le jeu se joue tout seul et dépose trente-trois images dans `docs/captures/` (les
  dernières montrent l'étal d'Ursule, la pause, le journal, l'équipe, l'inventaire, la
  boutique et, de `30_pause_talents` à `33_talents_sam`, l'écran de talents). Compter plutôt cinq à dix minutes si la fenêtre reste en arrière-plan.

## Organisation du projet

- `project.godot`, `scenes/main.tscn` : le strict minimum pour démarrer ; tout le reste
  est construit par le code.
- `src/core/` : commandes, chargement des données, état de la partie, sauvegarde, sons.
- `src/gfx/` : dessin des sprites et textures par le code, et point d'accès unique aux
  images (`sprite_library.gd`).
- `src/world/` : construction d'une carte, joueur, personnages, caméra, ambiance.
- `src/ui/` : écran-titre, boîte de dialogue, menu de pause, affichage en jeu,
  `game_menu.gd`, l'écran à liste commun à l'équipe, l'inventaire, le journal et les
  boutiques, et `talent_screen.gd`, l'écran de talents.
- `src/battle/` : le combat. `battle_engine.gd` contient **toutes les règles** sans rien
  afficher (c'est lui que les tests interrogent) ; `battle_scene.gd` construit l'arène et
  met les tours en scène ; `battle_actor.gd` anime un combattant ; `battle_ui.gd` est
  l'interface ; `rules.gd` calcule niveaux et statistiques ; `combatant.gd` décrit un
  combattant.
- `data/` : **tout le contenu** (personnages, ambiances, cartes, dialogues, compétences,
  objets, états, éléments, ennemis, rencontres, arènes, quêtes, boutiques). Le format est
  décrit dans `docs/FORMAT_DONNEES.md`.
- `assets/sprites/` : vide pour l'instant. Y déposer une image remplace le dessin généré
  (voir `assets/sprites/README.md`).
- `docs/HISTOIRE.md` : la bible de l'histoire. Mes inventions sont à la fin, section
  « Ajouts ».

## Décisions prises sans pouvoir demander

1. **Fichier de suivi.** Le cahier des charges annonce un fichier de suivi « décrit plus
   bas » mais ne le décrit pas. J'ai créé celui-ci.
2. **Noms des personnages : tranché par l'auteur le 18 novembre 2026.** La bible mélangeait
   deux séries de noms. Font foi partout : Sam Gamelle, Fripon Besace, Pépine Bontabac,
   Aragrogne, Légolasse, Gimlette. Les anciennes variantes ont été remplacées dans la
   bible, dans ce fichier et dans les données (voir décision 61). Ne plus les employer.
3. **Prologue.** Le combat du prologue est reporté à l'étape « combat ». À la place, une
   courte narration ouvre la partie, sans dévoiler le secret de Glandoulf.
4. **Heure.** Le village est montré au crépuscule : c'est l'heure qui met le mieux en
   valeur lanternes, fenêtres éclairées et halos.
5. **Collisions par le code**, sans moteur physique : une grille de cases plus des
   rectangles et des cercles. C'est simple, prévisible et facile à tester.
6. **Données en JSON.** Lisibles, modifiables à la main, sans passer par l'éditeur.
7. **Sauvegarde** dans un seul fichier (`user://sauvegarde.json`), une seule partie à la
   fois. Sauvegarde automatique à chaque changement de lieu.
8. **Son.** Aucun fichier audio : de petits bips sont fabriqués par le code. Pas de musique.
9. **Bâtiments de premier plan.** Une maison placée entre la caméra et le héros devient
   presque transparente, pour ne jamais cacher le bas de l'écran.
10. **Pas de `class_name`** dans les scripts : ils se chargent entre eux par leur chemin,
    ce qui évite de dépendre d'un cache que seul l'éditeur met à jour.

### Décisions de l'étape 2

11. **Noms.** La décision 2 est reconduite telle quelle (Sam Gamelle, Fripon, Pépine). Le
    roi du prologue s'appelle Isidur, comme dans la bible.
12. **Ordre des tours.** Pas de « manches » : chacun rejoue d'autant plus vite qu'il est
    rapide (une guêpe joue presque deux fois pendant que Glandoulf joue une fois). La file
    des prochains tours est toujours affichée.
13. **Faiblesses et bouclier**, à la manière d'Octopath Traveler : chaque ennemi a des
    faiblesses cachées (cases « ? ») et un bouclier chiffré. Un coup sur une faiblesse
    révèle la case, fait plus mal et entame le bouclier ; à zéro l'ennemi est « Ébranlé »
    (il passe un tour et encaisse moitié plus). Les faiblesses découvertes sont retenues
    d'un combat à l'autre et sauvegardées.
14. **Six éléments** : contondant, tranchant, feu, foudre, plante, torpeur. La torpeur est
    la spécialité de Glandoulf (bâillement contagieux, petit somme).
15. **Glandoulf repart du niveau 1.** Dans le prologue il est niveau 20 ; trois siècles
    sans lancer un sort plus tard, il a tout oublié (une réplique d'arrivée le dit). Rien
    de ce qui est gagné ou dépensé dans le prologue n'est conservé.
16. **Le prologue ne peut pas vraiment se perdre** en jouant normalement (100 % de
    victoires en jeu automatique), mais s'il est perdu on peut recommencer le combat.
17. **Défaite sans punition** : « Recommencer le combat » repart du début du combat ;
    « Retour à l'écran-titre » permet de reprendre la dernière sauvegarde. Rien n'est perdu.
18. **Rencontres seulement dans les champs** du Pré Couché, jamais sur la route ni dans le
    village : on choisit quand se battre. Les groupes d'ennemis s'adaptent à la taille de
    l'équipe. La fuite réussit trois fois sur quatre, jamais contre un boss.
19. **Pépine rejoint l'équipe dès maintenant**, simplement en lui reparlant, pour que les
    combats à plusieurs existent. C'est provisoire : sa vraie scène de recrutement (et
    celles de Sam et Fripon, déjà chiffrés dans les données) viendra avec les quêtes.
20. **Début de jeu doux.** Les ennemis du Pré Couché sont volontairement faciles : le
    joueur visé n'est pas un habitué. Monter de niveau rend tous les PV et le mana.
21. **La Grande Baveuse** et la racine-qui-réveille sont des inventions (voir
    `HISTOIRE.md`, « Ajouts ») pour donner un but à la première zone.
22. **Le prologue se joue sur fond noir** (narration puis combat dans l'arène du Grand
    Four) : il n'y a pas de carte de la Montagne du Festin à parcourir.
23. **Les compagnons ne suivent pas Glandoulf sur la carte** : ils n'apparaissent qu'en
    combat et dans le menu de pause.
24. **Mort au combat** : un allié à terre se relève avec 1 PV après une victoire.

### Décisions de l'étape 4

25. **L'étape 3 est sautée**, conformément à la consigne de la session. Rien de l'étape 4
    n'en dépend ; les talents pourront s'ajouter ensuite.
26. **Les quêtes se pilotent toutes seules.** Une quête démarre et s'achève quand ses
    conditions (dans `quests.json`) deviennent vraies : les dialogues se contentent de
    poser des drapeaux. Une ancienne sauvegarde retrouve ainsi son journal sans rien faire.
27. **Le journal ne montre que l'étape en cours** et celles déjà faites, pour ne pas
    dévoiler la suite.
28. **Trois emplacements d'équipement** : arme, tenue, babiole. Certaines armes sont
    réservées à un personnage. Un objet porté quitte le sac ; il faut le retirer pour le
    vendre.
29. **La monnaie s'appelle l'écu** (le mot figurait déjà sur l'écran de victoire).
30. **Ursule rachète à moitié prix.** Les objets de quête et les objets sans prix (la
    poêle, la pipe, le tuteur) ne se vendent pas.
31. **Le Ramollissement touche tout le monde**, ennemis compris : c'est le lieu qui est
    atteint, pas un camp. Il ne réduit que les coups physiques, ce qui avantage la magie
    de Glandoulf et donne une raison de chercher le tuteur ou le remontant. L'état
    « Ramolli » (attaque réduite, posé par l'épouvantail) existe toujours et s'y ajoute.
32. **Bittebourg est légèrement touché (10 %)** bien qu'on ne s'y batte pas encore : le
    témoin prépare le boss du chapitre.
33. **Une recrue arrive un niveau sous Glandoulf** au lieu du niveau 1, pour ne pas être
    un poids mort si on la recrute tard.
34. **Sam arrive avec sa poêle équipée** ; celle qu'on a rachetée est retirée du sac au
    moment où on la lui rend.
35. **La poêle coûte 40 écus.** On les réunit sans combattre (12 écus rendus par Fripon,
    30 pour les bittes de Gédéon) ou en combattant (la Grande Baveuse en donne 40).
36. **Le potager ne consomme pas de racine** : Pépine en avait « gardé un brin dans sa
    poche ». Ainsi la quête ne peut pas se bloquer si le joueur a utilisé ses trois
    racines en combat.
37. **Pépine rejoint toujours l'équipe en lui reparlant** (décision 19) : elle part
    chercher la racine avec Glandoulf, et confirme qu'elle le suit une fois le potager
    sauvé. Ce n'est donc plus provisoire.
38. **Ursule Bonpoids**, la marchande, et son commerce « d'occasion » sont des inventions
    (voir `HISTOIRE.md`, « Ajouts »).
39. **Lecture des fichiers.** Les outils de lecture habituels étaient refusés pendant
    cette session ; les fichiers ont été lus et modifiés par des commandes de terminal.
    Cela ne change rien au résultat.

### Décisions de l'étape 5

40. **Quand la Fête commence.** La bible dit seulement que la Fête approche. J'ai choisi
    que le joueur décide : une fois Pépine, Sam et Fripon recrutés et le potager soigné,
    Berthe propose de « dormir jusqu'à la Fête ». Rien ne presse avant, rien n'est perdu
    après : les quatre annexes restent faisables pendant la Fête et même après le Naze.
41. **Aucune quête ne peut être manquée.** La cérémonie se lance par un choix explicite
    (« l'histoire avance »). Pendant l'invasion, les villageois sont rentrés chez eux,
    mais Berthe garde l'auberge ouverte pour se reposer, et les zones restent accessibles.
42. **Structure de l'invasion.** Trois groupes de Morfales à chasser dans l'ordre que
    l'on veut, puis le Naze. Le Naze attend : on peut repartir s'entraîner. Une défaite
    n'est pas punie (« Recommencer le combat »).
43. **Le Naze n'est pas tué.** Il s'enfuit vers l'amont en annonçant que ses « frères »
    seront à Morbier avant l'équipe : cela prépare les chapitres suivants sans contredire
    la bible, qui garde les Nazes pour plus tard.
44. **La révélation.** C'est le Naze, en lisant le registre de la Capitainerie, qui relie
    le pêcheur disparu (Trempette, futur Goulûm) à l'anneau. Glandoulf explique l'anneau
    à ses compagnons mais ne dit toujours pas qui devait le détruire.
45. **Les zones annexes** (Bois Penché, Roselière) et leurs deux boss sont des inventions,
    ainsi que Basile Trempette, Nestor Boutdebois et les frères Godille (voir
    `HISTOIRE.md`, « Ajouts »).
46. **La course de barques est une scène à choix**, pas un mini-jeu d'adresse : trois
    décisions, dont les bonnes réponses sont soufflées par Odilon et par Basile. On peut
    la retenter autant de fois qu'on veut.
47. **Le concours de cuisine** laisse choisir le plat ; le jury récompense toujours, mais
    le premier prix (la louche d'or) demande les deux ingrédients.
48. **Équilibre visé**, mesuré par des combats simulés (trente par cas, l'ordinateur
    jouant l'équipe) : rencontres ordinaires gagnées à plus de 90 % au niveau prévu ;
    Vieux Solitaire et Monseigneur faisables dès les niveaux 4 et 5 ; le Naze presque
    imbattable au niveau 5 (10 %), sûr au niveau 6 (97 %, la moitié des PV restants) et
    confortable au niveau 7. Un joueur qui fait les annexes arrive au Naze au niveau 7
    ou 8 ; celui qui fonce, au niveau 5 ou 6, et devra passer par le bois ou la roselière.
49. **Ajouts au moteur**, tous pilotés par les fichiers de données : un ennemi peut
    changer de tactique sous un seuil de PV (`ai_low`) ; un effet peut porter des dégâts
    fixes (`flat`) ; un dialogue peut changer de chapitre (`chapter`) et afficher un
    bandeau (`banner`) ; une caisse peut porter un dialogue (l'estrade).
50. **Fin du chapitre.** Le chapitre 2 n'existe pas encore : la fin du chapitre 1 pose
    `chapter = chapitre_2`, sauvegarde, l'annonce, et laisse le joueur revenir dans le
    Comté. Le bout de la route de Brie est un cul-de-sac assumé.
51. **Lecture des fichiers** : comme à l'étape 4, par commandes de terminal.

### Décisions de l'étape 3 (rattrapage)

52. **Ce qui existait déjà n'a pas été refait.** L'écran d'équipe et les recrutements de
    Pépine, Sam et Fripon datent de l'étape 4 et fonctionnent ; seuls les talents
    manquaient. La fiche d'un personnage a simplement gagné un niveau de menu
    (« Équipement », « Talents »).
53. **Un point de talent par niveau**, à partir du niveau 2. Une voie entière coûte six
    points (1 + 1 + 2 + 2) : en fin de chapitre 1 (niveaux 7 ou 8) on a fini une voie, ou
    entamé les deux. C'est la rareté des points qui fait la spécialisation.
54. **On ne choisit pas une voie une fois pour toutes.** La bible dit « l'une ou l'autre » ;
    j'ai préféré laisser piocher dans les deux, les talents d'une voie s'apprenant dans
    l'ordre. La fiche affiche comme « Voie » celle où l'on a mis le plus de points.
55. **« Tout oublier » est gratuit et sans limite.** Le joueur visé n'est pas un habitué :
    aucun choix de talent ne doit pouvoir gâcher une partie.
56. **Les sept personnages de la bible ont leurs talents**, y compris Aragrogne, Légolasse
    et Gimlette, qui n'entrent en scène qu'aux chapitres suivants. Ils ont reçu une fiche de
    combat, une compétence de départ et une apparence provisoires pour que leurs talents
    puissent être testés dès maintenant. Leurs noms sont ceux de la décision 2.
57. **Le prologue ne connaît pas les talents** : Glandoulf et Isidur y ont leurs sorts de
    niveau 20, rien de plus. Les talents se découvrent au premier niveau gagné.
58. **Vol d'écus.** La Fauche de Fripon vole la moitié des écus qu'un adversaire aurait
    donnés, une fois par adversaire, en plus du butin normal. Ce qui est volé est gardé
    même si l'équipe fuit.
59. **Rééquilibrage : seul le Naze a bougé.** Mesurés par simulation avec les talents
    dépensés, les autres combats du chapitre changent peu (quelques points de PV restants
    en plus). Le Naze, lui, devenait battable trois fois sur quatre au niveau 5 : il passe
    de 1250 à 1350 PV, de 27 à 30 d'attaque et de 20 à 21 de magie. Résultat avec talents :
    20 à 37 % de victoires au niveau 5, 95 à 100 % au niveau 6, 100 % au niveau 7,
    conformément à la décision 48. Une équipe qui n'aurait dépensé aucun point gagne
    encore deux fois sur trois au niveau 6 et neuf fois sur dix au niveau 7.
60. **Les compagnons simulés jouent mal leurs talents.** L'ordinateur qui joue l'équipe
    dans les combats simulés ne lance ni provocation, ni renfort, ni sort de zone : les
    mesures sous-estiment donc ce qu'un joueur tirera des talents. Si le chapitre paraît
    trop facile en vrai, c'est le premier endroit où regarder.

### Décisions de la reprise de l'étape 3 (18 novembre 2026)

61. **Noms.** Les identifiants internes suivent les noms définitifs (`aragrogne`,
    `legolasse`, `gimlette`) pour qu'aucun ancien nom ne traîne dans les données. Aucun de
    ces trois personnages n'est encore jouable : les sauvegardes existantes ne sont pas
    touchées. Le nom complet de Fripon devient « Fripon Besace » ; la réplique où il se
    présentait a été réécrite (« Ici, on dit “le petit Besace”. Ça changera. »), ce qui
    garde son ambition, clé du personnage. « Grolas » et « Poilin » ne figuraient que dans
    deux notes de ce fichier sur le chapitre 2 ; elles parlent maintenant d'Aragrogne,
    que la bible fait rencontrer à Brie.
62. **L'existant est gardé, pas refait.** Les règles, les 56 talents et leurs 26
    compétences passaient déjà le test complet (6 845 vérifications, 0 échec, avant toute
    modification). Les réécrire aurait coûté du temps sans rien apporter au joueur. Ce
    qui manquait vraiment, c'était de les voir.
63. **Un écran à part plutôt qu'une page de liste.** L'ancienne page (onze lignes, cases
    « [x] ») ne montrait ni les deux voies côte à côte ni l'ordre des talents. Le nouvel
    écran est un arbre : c'est ce que le mot « talents » promet. L'ancienne page a été
    supprimée pour ne pas entretenir deux écrans.
64. **« Talents » est un bouton du menu de pause**, à côté d'« Équipe », et il affiche le
    nombre de points à dépenser. Raison : enfoui deux niveaux sous « Équipe », l'écran
    n'avait pas été trouvé en jouant tout le chapitre.
65. **L'écran s'ouvre sur le premier personnage qui a des points**, curseur sur le premier
    talent qu'il peut apprendre : après une montée de niveau, il suffit d'appuyer sur
    Entrée. Passer le curseur sur un onglet change de personnage sans validation.
66. **Pas de nouveau rééquilibrage.** Les combats simulés ont été relancés avec et sans
    talents : les chiffres sont ceux des décisions 48 et 59 (rencontres ordinaires à 97-100 %,
    Naze à 20-37 % au niveau 5, 95-100 % au niveau 6 avec talents, 67 % sans aucun talent).
    Le Naze renforcé de la décision 59 reste donc le seul ajustement. À revoir dès que
    l'auteur aura joué avec les talents (voir décision 60).
67. **Les captures sont décrites par un assistant.** Dans cette session, l'outil qui affiche
    les images n'était pas disponible pour l'agent principal ; les captures de l'écran de
    talents ont été regardées par un agent secondaire, qui en a fait un rapport de défauts.

### Décisions des animations de combat (18 novembre 2026)

68. **Une animation porte le nom de sa compétence.** `animations.json` est indexé par
    l'identifiant de la compétence ou de l'objet ; un champ `anim` permet d'en emprunter
    une autre. Raison : ajouter une compétence ne demande alors qu'une entrée de plus, sans
    rien relier à la main, et un oubli se voit tout de suite dans le test.
69. **Les poses sont des mouvements du sprite entier** (pencher, bondir, s'aplatir, se
    retourner), pas de nouveaux dessins. Raison : les planches actuelles n'ont que des
    poses de marche, et l'étape suivante (pixel art) les refait entièrement ; dessiner des
    poses d'attaque maintenant aurait été du travail jeté. Les armes et objets brandis
    sont des sprites d'effets à part, ce qui marche aussi pour les ennemis.
70. **Sprites d'effets nets, sans transparence.** Un sprite translucide était flouté avec
    l'arrière-plan par le flou de profondeur (constaté sur les premières captures : effets
    pâles, « en damier », méconnaissables). Ils sont donc découpés franchement, comme les
    personnages, et disparaissent en rétrécissant au lieu de s'estomper.
71. **L'animation rend la main à l'instant de l'impact** (`impact`), et les chiffres de
    dégâts suivent. Les effets finissent seuls. Raison : garder le rythme des combats ; la
    plupart des animations durent entre 0,3 et 1 seconde avant l'impact.
72. **Le test joue les 107 animations pour de vrai**, en temps accéléré douze fois, et un
    combat entier avec animations. Raison : jusque-là les tests tournaient « sans
    animation », et une erreur dans une animation aurait bloqué l'auteur en plein combat.
73. **Les captures d'animation sont prises à l'horloge**, 0,09 s après l'impact, et non en
    comptant les images : l'écran de ce Mac tourne à 120 images par seconde et les
    premières captures tombaient en plein élan.
74. **Le journal de quêtes n'a pas été retouché pour le Naze.** L'auteur ne l'avait pas
    trouvé ; vérification faite, la quête principale déroule déjà les étapes une à une
    (compagnons, potager, dormir chez Berthe, estrade, Morfales, Naze). À revoir si
    l'auteur bute encore.

### Décisions du pixel art (18 novembre 2026)

75. **Les sprites restent peints par code**, à partir du même `look` qu'avant. Raison :
    rien dans l'éditeur, pas d'outil de dessin, et les vingt et un personnages profitent
    d'un coup de chaque amélioration. Un PNG déposé dans `assets/sprites/` garde la main.
76. **Cases de 32 × 48 conservées**, 11 colonnes. Raison : changer la taille des cases
    aurait déplacé tous les personnages dans le décor et les combats.
77. **Les poses de combat dessinées s'ajoutent aux mouvements du sprite** (élan, bond,
    bascule) au lieu de les remplacer : les deux se renforcent, et un PNG déposé sans ces
    poses continue de marcher.
78. **Morfales et Naze restent des « personnages »** (quatre directions, marche) avec un
    corps à eux, choisi par `species`. Raison : ils se promènent sur les cartes et parlent,
    ce qu'un sprite de monstre ne sait pas faire.
79. **Attaque et coup reçu des monstres : le dessin de repos avec un autre visage**, décrit
    par une petite table (`FACES`). Raison : treize monstres, sept familles ; redessiner
    chaque pose à la main aurait pris l'étape entière pour un gain peu visible en combat.
80. **Titou change de tunique** (bleu-vert au lieu d'ocre) : ses cheveux blonds se
    confondaient avec son vêtement.
81. **Le menu Équipe affiche « 1 point » au lieu de « 1 point de talent »** : avec le
    portrait, le texte était tronqué.

## Préparé pour la suite, mais pas fait

- `GameState.chapter` vaut `chapitre_2` à la fin du chapitre 1 : c'est le point
  d'accroche du chapitre suivant (Brie, le Poney Flagada, la rencontre d'Aragrogne).
- La Première Amarre est dans le sac (objet de quête) : elle peut servir plus tard.
- Aragrogne, Légolasse et Gimlette ont déjà leur fiche de combat et leurs talents
  (`characters.json`, `talents.json`) : il suffira de les faire entrer dans l'équipe par un
  dialogue. Leur apparence et leurs chiffres sont provisoires.
- Un talent, une voie ou un effet de talent s'ajoutent dans `talents.json` sans toucher au
  code, tant qu'ils utilisent les effets décrits dans `FORMAT_DONNEES.md`.
- Une boutique, une quête, une zone, une créature ou un boss s'ajoutent en écrivant des
  fichiers de données, sans toucher au code (voir `FORMAT_DONNEES.md`).
- Le Ramollissement d'une carte est un simple nombre dans son fichier : les chapitres
  suivants pourront le faire monter.

## Limites connues

- L'aspect n'a pas pu être contrôlé de mes propres yeux (voir le rapport de session) : il a
  été vérifié par captures d'écran décrites par un assistant, et par des mesures.
- Pixel art : les planches et douze paires de captures avant/après ont été décrites deux
  fois par un assistant (captures 7 sur 10, planches 6 puis 7 sur 10). Les dernières
  corrections (bras du coup reçu reliés au corps, déhanchement à la marche, bras sous le
  menton pendant un sort, cadrage des portraits, yeux plissés des monstres) sont testées
  par programme mais n'ont pas été redécrites.
- Le KO dessiné est un personnage tassé sur lui-même ; c'est la bascule du sprite en
  combat qui le couche. La marche de face reste discrète (pieds et bras bougent de deux
  à trois pixels). Glandoulf de dos est une colonne de robe assez raide.
- En combat les héros se chevauchent quand l'un d'eux passe devant les autres pour frapper.
- Pas de musique, pas d'options (volume, touches).
- Combat : les poses d'attaque, de sort, de coup reçu et de KO sont des mouvements du
  sprite entier (penché, bond, aplatissement), pas des dessins dédiés : les bras ne
  bougent pas, l'arme est un sprite à part. (Depuis le pixel art, un dessin de pose
  s'y ajoute pour les personnages et les monstres.)
- Animations de combat : neuf sur 107 ont été capturées (`34` à `42`) et décrites par un
  assistant, trois fois de suite ; note de lisibilité passée de 4 à 6 sur 10. Les derniers
  réglages (poêle plus petite, éclair moins éblouissant, oreillers plus gros, sanglier
  qui reste au contact) n'ont pas été redécrits. Les 98 autres ne sont vérifiées que par
  programme : elles se jouent, se terminent et nettoient l'écran, mais personne n'a jugé
  leur allure. Les sons n'ont été entendus par personne.
- Une capture fige un instant : certains effets (éclair, nourriture du banquet, anneaux du
  cri) sont déjà passés ou pas encore là sur l'image, sans que ce soit un défaut.
- Le feu d'artifice du Bouquet final masque en partie les ennemis pendant une demi-seconde.
- L'outil de captures quitte en plein combat et affiche des erreurs de fermeture du moteur
  graphique : sans effet sur le jeu.
- L'équilibre a été réglé par des combats simulés où l'ordinateur joue l'équipe, pas par
  un humain : il faudra l'ajuster après un vrai essai.
- Hors combat, seuls les objets qui rendent des PV ou du mana s'utilisent depuis le sac.
- Les nouveaux écrans (journal, équipe, inventaire, boutique) n'ont été vus par personne :
  les captures ont été prises, mais je n'ai pas pu les regarder pendant cette session.
  Mise en page, longueur des textes et lisibilité sont donc à vérifier en jouant.
- L'équilibre à quatre personnages et avec équipement n'a été contrôlé que par les combats
  simulés existants ; le Pré Couché devient sans doute trop facile en fin de chapitre.
- L'équipement ne change pas l'apparence des sprites.
- Le test automatique signale en fin de course des « ObjectDB instances leaked » : c'est
  un avertissement de fermeture du programme de test, sans effet sur le jeu.
- L'intérieur de l'auberge est une « maison de poupée » ouverte côté caméra, entourée de noir.
- Étape 5 : les trois nouvelles cartes, la place en fête et les sept nouveaux sprites de
  créatures (sanglier, grenouille, feu follet et variantes) n'ont été vus par personne.
  Leur construction, leurs collisions et l'accès à chaque objet sont vérifiés par
  programme, pas leur beauté.
- Étape 3 : l'écran de talents a été capturé (`30` à `33`) et décrit par un assistant, pas
  encore jugé par l'auteur en jouant. Le curseur au clavier est vérifié par le test ; la
  souris et la manette n'ont pas été essayées sur cet écran.
- La riposte d'un talent n'a pas d'animation propre (un texte, puis le coup reçu).
- Les récupérations de PV et de mana des talents ajoutent un petit temps d'affichage au
  début de chaque tour du personnage concerné.
- L'intérêt relatif des deux voies de chaque personnage n'a pas été jugé par un joueur.
- La durée du chapitre est une estimation, pas une mesure.
- La course de barques et le concours sont des scènes de dialogue, sans animation.
- Après la fin du chapitre 1, il n'y a rien au-delà de la butte de la route de Brie.
- Le jeu n'a été lancé que sur ce Mac (Apple M1 Max, Godot 4.7.2).
- La manette n'a pas été essayée.

## Pistes pour l'étape suivante

1. Jouer le chapitre 1 en entier et noter ce qui est trop dur, trop facile ou trop long :
   l'équilibre n'a été réglé que par simulation.
2. Retoucher ce que l'auteur trouvera laid ou peu lisible en jouant : sprites
   (`character_painter.gd`, `monster_painter.gd`), animations (`data/animations.json`).
3. Essayer les talents en jouant : vérifier que les deux voies de chacun font envie, que
   l'écran se lit bien, et retoucher les chiffres (`data/talents.json`).
4. Chapitre 2 : Brie, le Poney Flagada, la rencontre d'Aragrogne.
5. Musique et ambiance sonore, en particulier une musique de combat et une de fête.
6. Vraies poses dessinées pour les monstres (corps qui bouge, pas seulement le visage).
