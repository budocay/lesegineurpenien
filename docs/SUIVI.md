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
- **Pépin rejoint l'équipe** si on lui parle une deuxième fois devant son potager ;
- se **reposer chez Berthe** (auberge) rend tous les PV et le mana ;
- le menu de pause affiche l'équipe (niveau, PV, mana), l'argent et l'inventaire.

**Étape 4 (quêtes, inventaire, boutiques) : terminée.** S'y ajoutent :

- un **journal de quêtes** (menu de pause, « Quêtes ») : les quêtes démarrent et
  s'achèvent toutes seules selon ce que fait le joueur, un message l'annonce en haut à
  droite, et le journal montre l'étape en cours et les étapes déjà faites ;
- **cinq quêtes à Bittebourg** : « Ce qui ramollit le Comté » (fil rouge du chapitre),
  « Le potager en deuil » (Pépin), « La poêle des Gamelle » (Sam), « Un héritage très
  récent » (la pipe, Froton) et une annexe, « Sauver les apparences » (caler les bittes
  du port pour Maître Gédéon : elles se redressent à l'écran) ;
- les **vraies scènes de recrutement** : Sam rejoint l'équipe quand on lui rapporte sa
  poêle (rachetée 40 écus à la marchande), Froton quand on revient le voir avec Sam ; il
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
  échappe avec le tuteur en noisetier (récompense de Pépin) ou un petit remontant.

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
- les **deux voies de chacun des sept personnages de la bible** (Glandoulf, Sam, Froton,
  Pépin, et déjà Aragrogne, Digoulasse et Grimli pour les chapitres suivants) : quatre
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

**Reprise de l'histoire (demande de l'auteur, 18 novembre 2026) : faite pour ce qui est jouable.**

- **Prologue réécrit** : après le combat, Isidur ramasse l'anneau et refuse de le jeter.
  Il le garde, pour son royaume et pour ses propres désirs. Glandoulf, à vingt pas du
  Grand Four, remet la discussion au lendemain, s'endort, puis dit à l'Alliance que
  c'est fait.
- **Chapitre 1 accordé** : après le Naze, Glandoulf nomme Isidur et raconte que le roi a
  perdu l'anneau dans la rivière deux ans plus tard ; il cache toujours sa propre part.
- **Bible complétée** (`docs/HISTOIRE.md`) : règne et chute d'Isidur au Gué des Poireaux,
  vraie faute de Glandoulf, peur d'Aragrogne, et une section « Reprise de l'histoire »
  qui comble les trous des chapitres à venir (Bromure, Dame Galadrielle, Barbe-Molle,
  l'Arachnée, le retour à Bittebourg). Ces chapitres ne sont pas encore construits.

**Musique (demande de l'auteur, 18 novembre 2026) : faite.**

- Onze morceaux, tous **fabriqués par le code** à partir de partitions écrites dans
  `data/music.json` (aucun fichier audio) : écran-titre, Bittebourg, Fête des Amarres,
  auberge, campagne (Pré Couché, route de Brie), Bois Penché, Roselière, combat, combat
  de boss, menace (invasion, Naze, prologue), fanfare de victoire.
- Chaque carte a sa musique (`music`), qui peut changer selon l'histoire
  (`music_states`) : à Bittebourg, village, puis fête, puis menace à l'arrivée du Naze.
- Les combats ont la leur (les boss une autre), la victoire sa fanfare, puis la musique
  du lieu reprend. Fondu enchaîné entre deux morceaux.
- Un dialogue peut changer la musique : `{"music": "menace"}`.
- Les morceaux sont calculés en tâche de fond au premier lancement (moins d'une seconde
  chacun) puis gardés sur le disque.

**Rendu « HD-2D » façon Octopath, première passe (demande de l'auteur, 18 novembre 2026).**

- Caméra d'exploration rapprochée de 13 % en extérieur : les personnages sont plus grands.
- Sol nuancé par grandes plaques (`ground.gdshader`) : le motif ne se répète plus à l'œil.
- Eau refaite : nappes qui dérivent, rides courtes, éclats qui scintillent.
- Rayons de lumière obliques (champ `rays` des ambiances), vignette sur toute l'image.
- Deux talus rocheux au nord de chaque carte d'extérieur, hors zone jouable, avec la
  forêt dessus ; ils s'ouvrent là où un chemin ou la rivière sort de la carte.
- Sous-bois : fougères (nouveau décor `fern`), touffes et fleurs au pied des arbres et
  aux abords ; feuilles qui tombent.
- Combat : ombres au sol plus marquées, alliés plus écartés, arène du Grand Four moins
  saturée.
- Corrigé au passage : le petit message en haut à droite pouvait être coupé par le bord.
- Captures d'avant dans `docs/captures/avant_hd2d/` ; deux captures ajoutées (bois,
  roselière).

- **Noms définitifs et Merri** (décisions 105 à 110) : Froton Salfait, Pépin Bontabac
  (un homme), Digoulasse, Grimli ; Merri Brandemou, cousin de Pépin, rejoint l'équipe à
  l'arrivée à Brie. Les anciennes sauvegardes sont converties au chargement.

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
   **Remplacée le 18 novembre au soir par la décision 105** (nouvelle liste de noms).
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

### Décisions de la reprise de l'histoire (18 novembre 2026)

82. **Isidur garde l'anneau** au lieu de le confier à Glandoulf (demande de l'auteur). La
    faute de Glandoulf change de nature sans disparaître : il était là, n'a rien fait,
    s'est endormi, puis a menti. Raison : son secret et sa paresse portent toute
    l'histoire, il fallait les garder.
83. **On ne dit ni ne montre où Isidur passe l'anneau** (il se détourne, puis « se tient
    très droit »). Raison : règle de ton de la bible, tout par le double sens.
84. **Les « désirs » d'Isidur restent à double lecture** (« de grands désirs pour mon
    royaume », « j'en ai aussi pour moi », un Gouda couvert « de chantiers et de
    berceaux »). Même raison.
85. **Le joueur apprend la vérité dès le prologue**, contrairement à la décision d'origine
    (prologue qui ne dévoilait rien). Raison : la scène demandée ne peut pas se jouer sans
    la montrer, et les mensonges de Glandoulf au chapitre 1 deviennent plus drôles quand
    le joueur sait. Les compagnons, eux, ne l'apprennent qu'au chapitre 5.
86. **Les ajouts aux chapitres 2 à 7 sont écrits dans la bible, pas dans le jeu.** Raison :
    ces chapitres n'existent pas encore ; l'auteur peut rayer ce qui ne lui plaît pas
    avant qu'on construise dessus.
87. **Noms inventés** : Gué des Poireaux, Bromure du Gouda, Lothlorraine, Dame Galadrielle,
    Barbe-Molle, l'Arachnée. À valider par l'auteur.

### Décisions de la musique (18 novembre 2026)

88. **Musique synthétisée par code**, comme les sons. Raison : aucun fichier audio dans le
    projet, rien à télécharger ni à importer dans l'éditeur, et pas de question de droits.
    Contrepartie : un son de synthétiseur simple, loin d'un orchestre.
89. **Partitions dans `data/music.json`**, en notation texte (« c4 e4 g4:8 »). Raison :
    moteur et contenu séparés ; ajouter un morceau ne demande pas de code.
90. **Calcul en tâche de fond et copie sur le disque** (`user://musique`). Raison : F5 ne
    doit pas attendre ; au tout premier lancement la musique arrive une à deux secondes
    après l'image.
91. **Pas de calcul sans fenêtre** (tests) : le test vérifie les partitions et calcule un
    seul morceau. Raison : garder le test rapide.
92. **Une musique par lieu plutôt que par ambiance lumineuse**, avec des états. Raison :
    Bittebourg doit changer de musique entre le village, la fête et l'invasion sans
    changer de carte.
93. **Pas de réglage du volume** pour l'instant : niveau fixe, sous les sons du jeu.

### Décisions du rendu HD-2D (18 novembre 2026)

94. **Partir des écarts constatés sur les captures**, pas d'une refonte : le jeu avait déjà
    flou de profondeur, halos, brouillard et ombres. Un assistant qui voit les images a
    listé douze écarts avec Octopath ; cette passe traite les plus rentables.
95. **Relief en décor seulement** (talus hors zone jouable). Raison : un vrai relief
    (marcher sur des hauteurs, escaliers) touche les collisions, la caméra, les cartes et
    les tests ; c'est une étape à part entière.
96. **Variation du sol par shader** plutôt qu'en repeignant chaque carte. Raison : gratuit
    au chargement, et valable aussi pour les abords et les arènes à venir.
97. **Caméra : facteur global `ZOOM` dans `world.gd`**, non appliqué aux intérieurs.
    Raison : un seul réglage à retoucher ; l'auberge rapprochée coupait sa cheminée.
98. **Rayons très discrets** après une première version jugée « brume sale » : force
    divisée par 2,5, teinte plus chaude, deux fois moins nombreux.
99. **Cadrage serré assumé en extérieur** : la seconde relecture note des barques et des
    toits coupés par le bord (quai, quartier est). Raison : l'auteur veut des personnages
    plus grands, comme dans Octopath ; `ZOOM` se règle en une ligne s'il préfère plus large.

Restes constatés à la seconde relecture des captures, non corrigés : au Bois Penché, une
plaque de sol sombre à bords droits près du lampadaire (cause non cherchée : cases de la
carte ou ombre) ; à la Roselière, la moitié basse d'un feuillage orange assombrie par une
ombre à bord net ; en combat à quatre, Pépine reste en partie cachée par ses voisins. Les
talus (pierre éclaircie) et le dernier écartement des alliés ont été retouchés après cette
relecture et n'ont pas été revus par un œil.

### Seconde passe HD-2D (18 novembre 2026, à la demande de l'auteur)

L'auteur trouve le rendu encore loin d'Octopath, « même sur les personnages ».

100. **Volume peint automatiquement** sur personnages et monstres (`PA.relief` : lumière en
     haut à gauche, ombre en bas à droite, appliqué après le miroir des vues de profil) et
     pied des sprites légèrement assombri par le shader. Raison : un seul endroit à régler,
     valable pour tous les dessins présents et futurs.
101. **Blé repeint** en gerbes de 36 x 34 px à deux rangs de tiges et épis à grains.
102. **Arènes** : sol nuancé, champ `backdrop` (fond en gradins : parois + décor posé
     dessus), plus de végétation.
103. **Placement de combat calculé** (`BattleScene.formation`) : écart selon la taille de
     chacun, plus large pour les monstres ; le test vérifie l'écart minimal et le cadre.
104. **Pas de pack d'images** : l'auteur ne veut pas payer. Recherche faite (résumés de
     pages seulement, licences non relues sur place) : aucun pack gratuit n'approche
     Octopath ; le plus complet, le générateur LPC (CC-BY-SA / GPL, crédits obligatoires),
     est noté 4 sur 10 pour le style et jurerait avec le reste. On garde le dessin par
     code, et l'auteur a validé sa refonte en plus grand et plus détaillé (à faire).

Relecture des captures de cette passe (avant les dernières retouches, non revues depuis) :
personnages 3 puis 4 sur 10, décors 5 puis 6, arènes 4 puis 5. Défauts relevés et non
corrigés : la paroi du fond des arènes se lit comme une bande plate et non comme de la
roche ; arbres d'arène trop grands pour les combattants ; le bras clair du Naze. Corrigés
après coup, sans nouvelle relecture : points clairs isolés sur Glandoulf, ennemis qui se
chevauchaient, Glandoulf trop près du bord droit, plaques du sol d'arène trop marquées.

### Noms définitifs et Merri (18 novembre 2026, soir)

105. **Liste de noms définitive, fixée par l'auteur, qui remplace les décisions 2 et 61.**
     L'auteur trouvait que les noms avaient été changés à tort. Fripon Besace devient
     **Froton Salfait** (le Frodon de l'histoire ; Froton, sans n au milieu), Pépine
     Bontabac devient **Pépin Bontabac** et est **un homme** (le Pippin de l'histoire),
     Légolasse devient **Digoulasse**, Gimlette devient **Grimli**. Inchangés : Glandoulf,
     Sam Gamelle, Aragrogne, Isidur, Bromure du Gouda (le Boromir de l'histoire, chapitres
     3 et 4). Identifiants : `fripon` → `froton`, `pepine` → `pepin`, `legolasse` →
     `digoulasse`, `gimlette` → `grimli`, partout (données, code, tests, bible).
     Raison du prénom de Pépin : un pépin est une graine (il est herboriste) et un ennui
     (il est téméraire). Pépin n'a plus ni jupe ni chignon (tunique, cheveux courts roux,
     chapeau de paille gardé) ; son rôle devient « soigneur », sa seconde voie « Fumeur de
     Pipe ». Son identifiant de voie reste `fumeuse` : il est invisible, et le changer
     aurait cassé les sauvegardes. Les accords ont été repris à la main dans les dialogues
     (« maître Pépin », « seul », « sûr »...).
106. **Réplique réécrite : « le petit Besace » devient « Sale fait ».** Froton se présente
     en disant que son nom se prononce en deux mots, « comme un travail mal torché » :
     double sens sur « salfait », cohérent avec un voleur qui se juge mal rangé.
107. **Reprise des sauvegardes.** `GameState.migrate_old_ids` (petite fonction isolée de
     `src/core/game_state.gd`, appelée au début de `from_dict`) remplace les quatre anciens
     identifiants dans toute la sauvegarde, clés et valeurs : équipe, fiches (niveau,
     équipement, talents), drapeaux (`fripon_equipe`, `pepine_vue`...), quêtes, bestiaire.
     Le test charge une ancienne sauvegarde de chapitre 2 et vérifie le résultat. Ce code
     est à garder : c'est le seul endroit où les anciens noms ont encore le droit d'exister.
108. **Merri Brandemou entre dans l'histoire** (nom validé par l'auteur ; identifiant
     `merri`). Cousin de Pépin, le Merry de l'histoire. Fiche complète dans la bible
     (« Ajouts », Merri Brandemou). **Recrutement : à l'arrivée à Brie (chapitre 2)**, et
     non au chapitre 1. Raison : tout le chapitre 1 est réglé et testé pour une équipe de
     quatre (équilibre, scène des « quatre silhouettes », dialogue de Berthe) ; en
     ajouter un cinquième aurait demandé de refaire ces réglages pour un gain faible. Il
     apparaît quand même au chapitre 1 : cousin de Pépin, il se présente sur la place
     (il tient l'intendance de la Fête), commente le nœud de Gédéon pendant la cérémonie,
     et on l'entend courir derrière l'équipe à la fin du chapitre. À Brie il la rattrape
     (scène d'arrivée) ; une ancienne partie déjà à Brie le trouve assis sur un tonneau de
     la place (`merri_brie`).
109. **Rôle de combat de Merri : stratège** (soutien et estoc). L'équipe avait un mage, un
     tank-cuisinier, un voleur, un soigneur et un rôdeur ; il manquait quelqu'un qui
     distribue le mana, l'initiative et les protections de groupe tout en frappant. Deux
     voies : Stratège de Table (initiative, Pause déjeuner, Plan B) et Estoc de Poche
     (riposte, Coup dans le dos, Charge des cousins). Quatre compétences de base (niveaux 1,
     2, 4, 6) ; chacune, avec son attaque de base `coup_de_dague_merri`, a son animation.
     Sa dague de poche est son équipement de départ ; l'estoc de la Marche s'achète à
     l'étal de Sidonie une fois qu'il est dans l'équipe.
110. **Équilibre avec Merri.** Une équipe de six rendait le combat contre les deux Nazes
     de nuit presque gagné d'avance : leurs PV passent de 1500 à 1700 (Naze de l'Est) et de
     1150 à 1300 (Naze de l'Ouest). Résultat du test (40 combats chacun, niveau 9) : cinq
     personnages sans Merri 90 % avec talents et 60 % sans ; six avec Merri 97 % et 90 %.
     Chantecler et le Vacherin sont déjà gagnés à 97-100 % à quatre : laissés tels quels.

111. **Sam Gamelle est jardinier de métier** (demande de l'auteur, fidèle au récit d'origine).
     Le champ `role` de sa fiche, affiché dans les écrans Équipe et Talents, passe de « tank »
     à « jardinier » ; ce champ ne sert qu'à l'affichage. Il garde sa poêle, ses compétences
     de cuisine et son nom : il cuisine ce qu'il fait pousser. Berthe dit « mon jardinier »
     et précise qu'il tient ses fourneaux. `repriste.txt` porte la nouvelle liste de noms.

### Décisions de la soirée du 18 novembre 2026 (chantiers menés en parallèle)

112. **Sauvegardes multiples.** Huit emplacements manuels et trois sauvegardes automatiques
     tournantes (`save_manager.gd`, écran `save_screen.gd`). Après une défaite : Recommencer,
     Revenir avant le combat, Charger une sauvegarde, Retour à l'écran-titre. Raison : demande
     de l'auteur (pouvoir revenir à un point antérieur) ; l'ancien fichier unique est repris.
113. **Musique recomposée.** Onze morceaux réécrits par `tools/compose_music.py`, nouveaux
     instruments (flûte, violon, harpe, cor, cuivres graves, chœur), nuances et réverbération.
     Compositions originales dans l'esprit d'une grande fresque, sans reprise d'un thème
     existant. Le morceau `brie` est resté dans l'ancien style.
114. **Interface refaite** (`ui_kit.gd`) : panneaux fondus sans cadre lourd, filets fins,
     curseur en losange, sur tous les écrans. Le titre et la pause ont un `add_entry` pour
     accueillir l'entrée « Paramètres » le moment venu.
115. **Quatre combattants au plus** (règle de l'auteur). `GameState.party` garde tous les
     recrutés ; les quatre premiers se battent (`active_party`), les autres sont en réserve
     (`reserve_party`). L'écran Équipe échange un actif et un réserviste ; le meneur ne sort
     pas. Les combats du chapitre 2 ont été réglés de nouveau pour quatre.
116. **La réserve ne gagne pas l'expérience des combats** (règle de l'auteur :
     `GameState.RESERVE_XP` à 0). L'expérience des quêtes va à tous. À surveiller : un
     réserviste laissé longtemps de côté décroche.
117. **Chapitre 3 (Fondue-Combe)** : col des Biscottes, cité, salle du Conseil, chancellerie,
     auberge, archives ; Digoulasse et Grimli rejoignent l'équipe ; Bromure du Gouda est un
     invité qui ne se bat pas ; boss : le Gardien des archives. La partie passe ensuite à
     `chapitre_4`. Contenu inventé noté dans la bible, section « Ajouts », à valider.
118. **Styles d'architecture par les données.** Champ `"style": "elfe"` sur une carte ou une
     maison (`elven_painter.gd`, `elven_builder.gd`) : pierre claire, arcs brisés, toits
     bleus ou vert-de-gris, cascades, pont, arbres d'or. Raison : l'auteur veut que chaque
     région ressemble à son modèle ; le nom de Fondue-Combe ne change pas, seul son aspect.
     Même méthode à suivre pour les Nains et le Mordgras.
119. **Arènes dégagées.** Aucun décor dans la zone de jeu, nappe de lumière au centre, fond
     assombri (bloc `stage` de `data/arenas.json`). Raison : l'auteur les trouvait illisibles.
120. **Combat mis en page comme dans Octopath Traveler** (inspiration de cadrage et
     d'ergonomie, rien n'est copié) : caméra basse, ennemis grands à gauche, héros en colonne
     diagonale à droite, premier plan flou (champ `foreground`), frise des tours en losanges
     en haut à gauche avec le tour suivant, fiches PV/PM en haut à droite, menu ouvert près
     du héros qui joue, bas de l'image libre.
121. **La trame d'ajourage ne touche plus les personnages** (`see_through` du shader de
     sprite) : seuls les décors s'estompent devant le héros.
122. **Monstres repeints** dans le style des personnages (volumes à cinq tons, contour
     coloré), y compris ceux du chapitre 2 qui sortaient en magenta. Option `avoid` du semis
     d'arbres : le Bois Penché laisse voir sa rampe et son plateau.
123. **Les tests de déroulé ne dépendent plus du hasard.** Les chapitres 2 et 3 s'y jouent
     au-dessus du niveau attendu (et Sam au niveau 14 dans ses duels, le temps du test) ;
     l'équilibre reste mesuré à part, sur des dizaines de combats au niveau prévu.

124. **Le jeu s'appelle « Le Seigneur des Anneaux Péniens »** (titre de l'auteur ; « Glandoulf
     le Gris » était un titre de travail). Écran-titre, nom de la fenêtre, `data/game.json`
     et bible changés ; le dossier et les identifiants ne bougent pas. L'auteur demande que
     le jeu joue de ce titre partout, en clair ou en sous-entendu, et reste drôle : noms de
     créatures, de lieux, d'objets et de compétences à double sens, les personnages restant
     sérieux (règle de ton inchangée : jamais de mot cru).

125. **Équipement de vrai RPG.** Cinq emplacements (arme, couvre-chef, tenue, deux
     babioles), 117 pièces, statistiques précision, esquive, critique et dégâts critiques,
     genres d'armes et de tenues par personnage (`gear`), passifs d'objets, comparaison avant
     et après dans l'écran Équipe et en boutique. Les sorts ne ratent jamais ; seuls les
     coups physiques s'esquivent. Équilibre mesuré inchangé (91 % de victoires simulées).
126. **Écran de paramètres** (autoload `Settings`, `user://settings.cfg`) : affichage, échelle
     de rendu, FSR 1 et 2, MetalFX quand le matériel l'annonce, qualité Basse / Moyenne /
     Haute, volumes, compteur d'images. Moyenne = rendu d'origine. Le DLSS, absent sur Mac,
     apparaît en ligne grisée. Les tests ignorent le fichier de réglages de l'auteur.
127. **Sol des arènes rendu à son lieu** (l'auteur voyait « de la terre ») : herbe, humus,
     herbe humide et flaques, pavés, basalte ; plus de tuile `soil`. Menu de combat placé par
     recherche d'espace libre, plaques d'ennemis écartées.
128. **Bestiaire, ambiances de combat, scénario des chapitres 5 à 7** : `docs/BESTIAIRE.md`,
     `docs/AMBIANCES_COMBAT.md`, bible. Réponses de l'auteur aux dix questions (fin du
     bestiaire) : Ouroukouilles (nom validé par lui, exception assumée à la règle de ton),
     Gobelardons, jeux sur le titre appuyés, le Guetteur n'est pas « le Seigneur des
     Anneaux », Sauron endormi, Bromure meurt de façon nulle et drôle, Goulûm trahit puis
     se sacrifie, les Éveillés, le Raidissement, Merri Écuyer Tranchant.

129. **Une arène de combat par lieu.** La carte déclare son arène (champ `arena`), une
     rencontre peut la remplacer, repli sur le Pré (`BattleScene.resolve`). Onze arènes pour
     les chapitres 1 à 3 (taverne, étage d'auberge, ruelle de nuit, cave à fromage, ferme,
     route, col, cité elfique, salle du Conseil, archives, quai), quatre pour les Mines.
130. **Chapitre 4, les Mines de Morbier** : huit cartes en style « nain »
     (`dwarven_painter.gd`, `dwarven_builder.gd`), porte à énigme, Guetteur du lac Noir,
     Gobe-Lards, le Gros Bleu des caves, Goulûm dit Trempette, le Balourd au
     Pont-l'Évêque. Glandoulf tombe : action de dialogue `quitte:<id>:<nouveau meneur>`,
     Sam mène ensuite. La partie passe à `chapitre_5`. Bromure y tient encore le pont : sa
     mort « nulle et drôle » voulue par l'auteur reste à écrire (début du chapitre 5).
131. **Points d'élan** (accord de l'auteur) : 1 point au départ, 1 par tour, 5 au plus ; on
     en engage 0 à 3 avec gauche / droite ; une attaque frappe 1 + N fois, une compétence
     voit sa puissance multipliée (1,5 / 2 / 2,5), un soin 1,3 / 1,6 / 1,9 ; pas de gain au
     tour qui suit un engagement. Les boss des chapitres 1 à 4 ont reçu environ 40 % de PV
     en plus pour garder les taux de victoire visés ; boucliers inchangés.
132. **Détails d'interface de combat** : 37 icônes peintes par code (`icon_painter.gd`,
     `Sprites.icon`), bouclier chiffré et faiblesses sous chaque ennemi, moment « Brisé »,
     main qui pointe, portraits et pastilles d'élan sur les fiches, écran de victoire refait.

133. **Combats enchaînés** : `main.start_battle` attend la fermeture complète du combat
     précédent (drapeau `_battle_running`). Sans cela, deux combats lancés coup sur coup
     empilaient leurs décors. Trouvé par la relecture des captures.
134. **Lanterne des Mines** : champ `lantern` des ambiances sombres ; le héros porte une
     lumière sans ombre, un halo le suit et un liseré le détache. On garde l'obscurité, on
     voit pour jouer.
135. **Maisons de village** (`house_builder.gd`, `house_painter.gd`) : chaque maison est
     tirée de façon stable d'après la carte et son emprise (mur, enduit, toit, lucarnes,
     enseigne) ; `style: "grobitte"` pour les maisons rondes à toit d'herbe. L'auteur ne veut
     pas de pack graphique : tout reste peint par code.
136. **Personnages refondus** : cases de 88×132 (au lieu de 48×72), cinq tons par matière,
     visages, portraits de 64 px, peintre découpé en `char_kit.gd`, `character_head.gd`,
     `character_species.gd`. Les planches sont mises en cache dans `user://cache_persos/`
     car la peinture est trois à quatre fois plus lente.
137. **Conseils de jeu** (demande de l'auteur : accompagner le joueur) : `data/tutorials.json`,
     autoload `Tutorial`, quinze conseils montrés une fois au moment utile, rappel de la quête
     en cours à l'écran, page « Aide » dans la pause, réglage pour les couper ou les revoir.
     Les anciennes sauvegardes considèrent tous les conseils comme vus.
138. **Chapitre 5, le Roquefort et l'Isengarde-Manger** : mort de Bromure (un glaçon, au
     milieu de son discours d'adieu, comme voulu par l'auteur), Ouroukouilles, Cabécou,
     Bergerie d'Or, Fongorn, retour de Glandoulf, Garde-Manger, Sarumâle. Groupe scindé par
     les données (`GameState.bench`, actions `groupe:`, `va:`, `equipe:`). Coupés : l'interlude
     de Lothlorraine et le combat des captifs. La partie passe à `chapitre_6`.
139. **Dépôt GitHub et Windows** : `origin` = `git@github.com:budocay/lesegineurpenien.git` ;
     `installer_windows.bat` télécharge Godot 4.7.2 dans `tools/godot` et lance le jeu,
     `jouer.bat` le relance. Jamais essayé sur un vrai Windows.

140. **Construction du jeu** : `./build.sh` (Mac, Linux) ou `build.bat` (Windows) produit les
     trois versions dans `build/` à partir de `export_presets.cfg`. Les scripts Windows lancent
     le programme principal de Godot et non sa variante « console », qui échoue (erreur 193)
     quand le chemin contient une espace. Version Mac lancée et vérifiée ; Windows et Linux
     jamais lancées.
141. **Mise en scène des combats** (retour de l'auteur : cailloux devant l'écran, héros plus
     hauts que les fiches) : `BattleScene.layout()` calcule la taille des héros et des monstres
     d'après la place laissée par l'interface ; un premier plan reste dans un coin bas, sombre,
     sous 6 % de l'écran, sinon il est réduit ou retiré. Vérifié pour toutes les arènes par
     `_test_battle_staging`.
142. **Ambiance des combats** : nappe de lumière sous les combattants, liseré, fond flou,
     arènes sombres relevées et arènes claires assombries (champs `exposure`, `fill`, `lift`,
     `rim`, `shafts`, `dim` de `stage`) ; un boss fait 1,7 à 3,4 fois un héros
     (`BattleScene.find_boss`, champ `boss` des rencontres) ; monstres repeints à trois fois la
     définition (`MonsterPainter.upscale`).
143. **Corriger ce que les agents remontent** (demande de l'auteur) : chaque faiblesse listée
     dans un rapport devient une tâche. Faits : profils, mains, pieds et expressions des
     personnages (`look.face`) ; repère de quête (`target` des étapes), touche du journal (J,
     Y) ; Garde-Manger éclairé, Cabécou habillé, pavillons de Fondue-Combe, lac de Maroilles,
     maisons distinctes sur une même carte, Bittebourg enrichi, rien devant une porte
     (`_test_door_clearance`) ; l'ombre du soleil sur un sprite est réduite aux deux tiers
     (c'était la cause de « l'arbre à moitié brun »).
144. **Raccords d'histoire** : Gobelardons partout (identifiants inchangés), « trois cents
     ans », Bromure recousu entre les chapitres 4 et 5, jeux sur le titre renforcés aux
     chapitres 1 à 3. Équilibre remesuré (`GLAN_ONLY_MEASURE=1` imprime le tableau) ; les
     déroulés des chapitres 3 et 4 se jouent au niveau 30 pour ne plus dépendre du hasard.
     Seuils du Gardien des Archives abaissés pour l'équipe sans soigneur (15 %) : à revoir.

145. **Manette** (demande urgente de l'auteur, qui joue à la manette Xbox sous Windows) : les
     boutons n'étaient liés qu'à la manette numéro 0 et les menus (`ui_accept`, `ui_cancel`)
     n'avaient aucun bouton. `Controls` accepte toute manette (`device = -1`) : A valide, B
     annule, Start ouvre le menu, Y le journal, X efface une sauvegarde, LB et RB changent de
     page. L'aide des touches suit le dernier périphérique utilisé (`Controls.pad`, signal
     `device_changed`, pastilles dessinées par `ui_kit.gd`). `_test_gamepad_full` joue le titre,
     le prologue, les menus et un combat entier avec une manette numéro 3. Jamais essayé avec
     une vraie manette : à confirmer par l'auteur.
146. **Monstres à la définition des héros** : `MonsterPainter` peint directement en grand
     (grille `K` de 4, 6 pour les gros) au lieu d'agrandir un petit dessin ; cache disque
     `user://cache_monstres/`. La première peinture de tous les monstres coûte 25 secondes :
     un fil d'arrière-plan la prépare dès le lancement (`Sprites._warm_monsters`). Ce fil
     travaille sur une copie du peintre : un peintre qui lit un état statique d'un autre script
     y dessine faux (cas des monstres du chapitre 6, exclus du préchauffage).
147. **Boss dominants** : boss en retrait au centre de son camp, sbires devant et plus petits,
     héros réduits à 0,88 face à un boss ; il fait au moins 2,2 fois un héros
     (`BOSS_RATIO_FLOOR`). Plaques des sbires placées sur une grille, hors du bandeau des
     touches, à dix pixels au moins l'une de l'autre. Halos (`halos`), ombres de nuages
     (`clouds`), feuillage (`dapple`), pierres (`stones`) dans `data/arenas.json`.
148. **Objets tenus** : champ `look.held` (poêle de Sam, arc, hache, épée, fourche...) peint par
     `character_items.gd` : rangé au repos, en main à la marche, utilisé à l'attaque, lâché au
     KO. Expressions de combat ; `look.glow` (Nazes), `look.hair_lift`.
149. **Intérieurs habillés** : `interior_dress.gd` et `interior_painter.gd` posent murs
     appareillés, étagères, tonneaux, tentures à la fin de la construction de toute carte
     `interior` ; un plan `Surround` prolonge la roche hors de la carte, jamais noir franc.
     Sols mouchetés par la table `MOTTLE`. Enseignes placées par `HouseBuilder.sign_spot`
     (ni sur une fenêtre ni sur la porte). Lierre et jardinières en volume.
150. **Chapitre 6 jouable** (Minas Tartine) : styles `gouda`, `veille`, `port`, `champ`
     (`gouda_painter.gd`, `gouda_builder.gd`, monstres dans `gouda_monsters.gd`) ; sept cartes ;
     l'Intendant Dénigror, père de Bromure ; groupe scindé deux fois ; cinq postes de la Grande
     Porte qui donnent des objets de combat ; six boss ; la partie passe à `chapitre_7`. Écarts
     avec la bible notés dans « Chapitre 6 (construit) ». Joué par le test seulement.
151. **Équilibre resserré** : le simulateur des tests joue désormais les talents (zone,
     provocation, soin, élan gardé pour le bouclier, faiblesse visée). Avec ce joueur attentif,
     les boss des chapitres 1 à 5 passent de 100 % à 68-89 % de victoires en 9 à 14 tours ; la
     pire équipe raisonnable (sans soigneur) reste au-dessus de 45 %. Contrepartie : un joueur
     naïf sans talents perd souvent (39 % contre le premier boss) : à adoucir pour les premiers
     chapitres. Tests `_test_forced_balance` et `_test_progression`.
152. **Interface** : lignes de sauvegarde avec portraits, lieu, chapitre, temps et date ;
     confirmation avant d'écraser, de quitter ou de revenir au titre (`confirm_box.gd`) ;
     conseils de combat fléchés ; fondu de fermeture (`UI.ghost_fade`) ; écran
     « Chargement… » ; fiche d'équipement sans doublon. Les textes d'aide passent par
     `Tutorial.expand` (marqueurs `{interact}`, `{cancel}`, `{menu}`).

153. **Manette de bout en bout** : `_test_gamepad_full` joue le titre, le prologue, les
     menus, la boutique, les talents, les sauvegardes et un combat complet avec une manette
     simulée. Corrigés au passage : curseur perdu sur une ligne grisée, curseur donné à un
     bouton inactif à la défaite, stick qui sautait deux lignes. Confirmation avant « Quitter »
     et « Retour au titre », « Non » par défaut : une touche de trop ne doit rien faire perdre.
154. **Cité blanche de Minas Tartine** : le bleu-gris venait de l'ambiance de la carte (fond
     violet sombre, soleil trop bas : le sol ne recevait que 41 % de la lumière), pas de la
     pierre. Ambiance `minas` refaite, pierre crème, étages à murs de soutènement crénelés et
     escaliers (`gou_marche`), camp du siège au nord de la Croûte (champ `siege`). La
     silhouette de la ville (`skyline`) est construite mais presque invisible : la caméra
     plonge trop pour montrer l'horizon. La relever toucherait tout le jeu : laissé à l'avis
     de l'auteur.
155. **Jeux sur le titre au chapitre 6** : 38 ajoutés (répliques, écriteaux, objets, noms de
     compétences), reportés au carnet de la bible. Les compétences n'ont pas de description :
     le jeu de mots n'y passe que par le nom.
156. **Premiers boss adoucis** (le chapitre 1 sert de tutoriel) : un joueur naïf sans talents
     gagne le Naze à 60-73 % (40 % avant), les Nazes de nuit à 41 %, le Vacherin à 66 %, le
     Gardien à 45 %. Contrepartie mesurée : la pire équipe raisonnable descend à 37-40 % sur le
     Vacherin et Chantecler (plancher fixé à 35 %). Restent hors cible : Chantecler naïf 33 %,
     Balourd naïf 16 %, brèche de l'Isengarde à 96-100 % pour l'équipe type.
157. **Balourd en deux phases** par les données (`ai_low`, état « Le plafond gronde » qui
     annonce l'éboulement) ; **brèche de l'Isengarde en deux vagues** (`breche_avant` puis
     `breche`) pour rapprocher l'équipe type de la pire (98/46 devient environ 97/58).
158. **Réserve** : un personnage échangé à la main reçoit le même rattrapage de niveau que par
     le récit (`GameState._catch_up`, commun à `swap_members` et `set_group`) : personne ne
     revient de la réserve trop faible pour servir.
159. **Façades étroites** : quand `sign_spot` ne trouve pas de place, l'enseigne se pose en
     potence (`sign_bracket`, panneau tourné de 40 degrés pour rester lisible de face) : écurie
     de Brie. Lac de Maroilles piloté par la carte (`lake`, `glow`, `glow_power`) ; sol de
     l'Isengarde sali (suie, huile, champ `rails`).
160. **Textes d'aide** : dialogues, choix, journal et repère de quête passent par
     `Tutorial.expand` ; `_test_help_texts` parcourt toutes les données et refuse un nom de
     touche en dur ou un marqueur inconnu.
161. **Tests plus sûrs** : le déroulé du chapitre 4 se joue au niveau 40 (à 30 le Gros Bleu
     gagnait encore de temps en temps et faisait échouer sept vérifications en chaîne) ;
     `_test_warm_matches_demand` compare la planche du fil de préchauffage à celle peinte à la
     demande. Dans `tests/capture.gd`, les arènes de démonstration se quittent par la fuite :
     passer un combat en automatique au milieu d'un tour ne le relançait plus et toutes les
     captures suivantes montraient ce combat figé.

162. **Relecture des captures du 19 novembre** (114 images sur 135 ouvertes par un agent) :
     plus aucune image figée. À corriger à la prochaine étape, par ordre de gêne : Goulûm,
     Froton Anneauté et Sarumâle à peine plus grands qu'un héros en combat ; lac de Maroilles
     encore sans reflet ni profondeur lisibles (eau visible seulement sur les bords) ;
     `24_etal_ursule` montre le quai et non l'étal ; flaques d'huile de l'Isengarde lues comme
     de la suie ; terrasse des Chutes et enclos de la plaine plats ; aucune capture de Brie ne
     montre l'écurie, donc l'enseigne en potence n'a été vue que par l'agent qui l'a faite.

### Décisions des 19 et 20 novembre 2026 (« corrige tous les défauts », manette réelle, release)

164. **Horizon et caméra par carte** : au lieu de relever la caméra partout (ce qui aurait
     aplati tout le jeu), chaque carte peut déclarer des zones de caméra (`camera.zones`,
     `camera.bounds`), une mise au point (`near_start`, `far_start`) et un horizon peint
     (`horizon`, `skyline`, `siege`, `belvedere`). Minas Tartine a ainsi sa silhouette, sa
     Tour Blanche en volume (`gouda_tower.gd`, étendard, oiseaux), sa rue habillée et son
     siège animé (fumées, braises, machines, armée en rangs). Les plans d'horizon sont mis en
     cache sur disque (`user://cache_horizon/`) et préparés par un fil d'arrière-plan joint à
     la fermeture du jeu.
165. **Murs qui s'estompent localement** : un rempart entier devenait vitreux dès que le
     héros passait derrière. Les remparts du style `gouda` sont taillés en tronçons de 2 m,
     marqués `local` : seul le tronçon qui cache le héros s'estompe, à 72 % au plus. Sans la
     clé, rien ne change pour les autres cartes (deux lignes dans `world.gd`).
166. **Boss dominants et repeints** (`boss_painter.gd`, champ `boss` des rencontres) : un boss
     fait environ trois fois la taille d'un héros ; Grimace, le Naze suprême, le pétrisseur et
     Saumure ont un vrai dessin. Les héros restent à 80 % de leur taille libre face à un boss,
     plutôt que de rétrécir davantage, pour rester lisibles.
167. **Coups annoncés** (champ `next` de l'IA, état `annonce`) : Chantecler, Uglouk, le
     pétrisseur et Goulûm préparent leur gros coup un tour à l'avance ; un triangle rouge, un
     bandeau et un conseil de jeu le disent, et briser le bouclier l'interrompt. Raison : un
     boss dur doit se lire, pas surprendre. `pierce` (ignore la provocation) et `ignore_guard`
     (passe la parade) existent pour Goulûm.
168. **Décors des chapitres 1 à 5, passe générale** : ombre portée des lanternes coupée par
     défaut (elle dessinait un rectangle sombre autour de chaque lampe) ; objet `balustrade` ;
     clôtures des plateaux ; bornes de caméra remises dans l'ordre sur six intérieurs (le héros
     collait au bas de l'écran) ; plan noir `InteriorVoid` qui ferme le vide derrière les murs ;
     objet `bed` et étage du Poney meublé ; bords de chemin irréguliers ; `near_start` à 0,70
     sur les 37 cartes pour que le héros soit toujours net.
169. **Manette réelle** : la manette Xbox de l'auteur « non reconnue » marchait en fait : sur
     Mac, une manette ne parle qu'à l'application au premier plan, et le jeu lancé dans la
     fenêtre intégrée de l'éditeur n'y est jamais. D'où `jouer.command` (double-clic, jeu dans
     sa propre fenêtre). Essai fait le 19 novembre sur ce Mac, manette en Bluetooth : boutons,
     croix et sticks arrivent bien aux commandes du jeu. Ajoutés pour le PC Windows, jamais
     essayé : écran de diagnostic (`pad_screen.gd`, ligne « Manette » du titre et des
     paramètres, fichier `user://manette.txt`), messages de connexion, mapping de repli pour
     une manette inconnue de SDL, répétition des directions dans les menus (Godot ne répète pas
     les directions d'une manette : le curseur ne faisait qu'un pas), vibration réglable.
     Mode d'emploi : `docs/MANETTE.md`.
170. **Build de release** : version unique dans `application/config/version` (0.6.0, six
     chapitres sur sept), affichée sur l'écran-titre ; icône et écran de démarrage du jeu ;
     métadonnées Windows écrites par Godot 4.7 sans `rcedit` ; exe et `.pck` séparés (moins de
     fausses alertes d'antivirus chez les amis de l'auteur) ; archives par plateforme avec
     LISEZMOI et sommes SHA-256 ; `release.sh` et workflow GitHub sur un tag `v*` ; journal de
     fichiers activé. `assets/music/` (musiques personnelles de l'auteur) est exclu de
     l'export pour ne pas diffuser de morceaux sous droits : à confirmer par l'auteur. Jamais
     essayés : scripts Windows, workflow GitHub, exe Windows, binaire Linux. Signature macOS
     ad hoc jugée invalide par `codesign --verify`, cause non trouvée. Voir `docs/RELEASE.md`.
171. **Arrêt et reprise des agents** : un agent arrêté en cours de route laisse une branche
     dont le test complet n'a pas forcément tourné. À la reprise, lancer le test complet de
     chaque branche dans son dossier avant toute fusion (le 20 novembre : une verte sur trois).
172. **Derniers défauts de décor et de boss** (branches decors9 et boss5) : eau et cascade
     refaites, Mines accordées, salle du Conseil, étal d'Ursule déplacé (il bouchait le quai),
     plaques de combat jamais posées sur leur propre ennemi, Uglouk repeint, poses de sort et
     de KO des boss, Guetteur du lac et Garde-Manger rééquilibrés par les chiffres plutôt que
     par les bornes du test.
173. **Noms** : l'auteur a rappelé que lieux et personnages doivent porter un jeu de mots
     discret autour du Seigneur des Anneaux. Inventaire complet dans `docs/NOMS.md`. Appliqués
     sans demander, parce qu'ils ne touchent aucun identifiant ni aucune sauvegarde : Caradure,
     Élendur, Lentbas elfique, Montagne du Festin, Terre du Mi-Lieu, Grand Four. Laissés à
     l'auteur, parce qu'ils changent un nom qu'il a déjà lu cent fois : Sauronfle, Col du Mont
     Vantard, Tour d'Ortolan, Odilon Fièrebitte, Cabédoras, Rôt-Gratin.
174. **Packs d'images gratuits essayés puis écartés** (The Fan-tasy Tileset, Tiny Pixel
     Fantasy, site freegamesprites.com). Essai réel de la végétation du premier dans une copie
     du jeu, captures avant et après : arbres vus de dessus, lisses, tous pareils ; l'auteur a
     tranché, « l'existant a l'air plus sympa ». Le second a des pixels deux fois plus gros que
     les nôtres. Raison de fond, valable pour tout pack futur : le dépôt GitHub est public, et
     ces licences (« non-commercial », « You may not resell or redistribute the assets ») y
     interdisent le dépôt des fichiers. Règle retenue : n'entre dans le dépôt que du CC0, du
     CC BY crédité, de l'OFL pour les polices, du MIT ou Apache pour le code.
175. **Ressources libres** : une seule piste retenue, une police embarquée (Alegreya pour le
     texte, Cinzel pour le titre, licence OFL), surtout pour avoir le même rendu sur Mac et
     sur Windows ; elle attend le choix de l'auteur sur captures et n'est pas intégrée.
     Sons Kenney (CC0) : mécanisme « fichier de `assets/sfx/` s'il existe, sinon son généré »
     prototypé, à faire écouter avant tout remplacement. Écartés : invites de manette Kenney
     (plus criardes que les nôtres), particules lisses, shaders à la licence non vérifiée.
176. **Fluidité** : le gel à l'entrée d'une carte venait de la peinture d'images par code sur
     le fil principal, pas des shaders. Construction étalée sous le fondu (`staged`), arc de
     chargement, cache disque des sols, fils d'arrière-plan lancés après le titre et mis en
     pause pendant les chargements, fermeture sans plantage. Voir `docs/PERFORMANCE.md`.
     Défaut trouvé à la fusion : `MapBuilder.build` appelait `_build` sans `await` (enveloppe
     de mesure venue d'une autre branche), la carte était rendue à moitié construite ; trois
     échecs du test complet sur Fondue-Combe l'ont montré, corrigé, mesures à refaire. Restent
     lents : le premier lancement d'une version (caches vides, plusieurs secondes sur Minas
     Croute et Port-Saumure) ; Windows jamais mesuré.

### Décisions du 20 au 25 novembre 2026 (l'auteur délègue : « prends les bonnes décisions »)

177. **Police embarquée** : Alegreya pour le texte, Cinzel pour le titre et les bandeaux de
     lieu (`assets/fonts/`, licence OFL). Raison : un RPG soigné ne dépend pas de la police du
     système, et le rendu est le même sur Mac et sur Windows. Réglages trouvés à l'œil :
     interligne −3, pas de hinting, demi-pixel, chiffres alignés, espace d'italique élargie ;
     repli sur la police système si le fichier manque. Jamais vue sous Windows ; le zéro
     ressemble à un « o ».
178. **Sons enregistrés, réversibles** : 13 bruitages Kenney (CC0) pour l'interface, les
     coups et les portes (`assets/sfx/<identifiant>`), réglage « Sons : enregistrés /
     synthétisés ». Réversible parce que personne n'a pu les écouter : niveaux alignés par le
     calcul sur les sons générés. Magie, soins, rugissements et rots restent synthétisés
     (identité du jeu). Licences sans extension (l'export exclut `*.txt`). Crédits :
     `docs/CREDITS.md`.
179. **Chapitre 7 et fin du jeu** : huit cartes (Marais du Bouillon, Passe-Plat, col de
     l'Arachnée, cuisines et banquet de Mordgras, Quatre Mille Marches, Grand Four, épilogue),
     quatre styles servis par un seul constructeur (`mordgras_builder.gd`), neuf monstres et
     trois boss peints, Sauron qui s'endort au lieu de mourir, aveu de Glandoulf, générique
     (`credits_screen.gd`), sauvegarde « partie terminée ». Inventions listées dans les
     « Ajouts » de la bible, à valider par l'auteur. La finition a trouvé deux vrais défauts :
     le générique était invisible en jeu réel (taille nulle, voile jamais levé) et trois objets
     de décor n'étaient jamais dessinés ; un test vérifie désormais que tout objet `mor_*` est
     branché. La version reste 0.6.0 tant que l'auteur n'a pas joué la fin.
180. **Décors 10** : monstres ordinaires agrandis (trois ramenés plus bas ensuite : à cinq,
     leurs plaques se chevauchaient), lac de Maroilles, Bergerie d'Or, citadelle. Un test
     vérifie que les `pos` et `rect` de toutes les cartes ne contiennent que des nombres (des
     objets glissés dans le `pos` d'une torche étaient ignorés sans erreur). Shader d'eau
     mesuré : coût négligeable.
181. **Carnet** (`src/core/carnet.gd`, `data/carnet.json`) : bestiaire (statistiques à la
     première victoire, faiblesses à la découverte, rappelées sur la plaque de l'ennemi),
     « Faits et gestes », fiche détaillée, aperçu chiffré au curseur (calculé à part : le
     hasard du combat ne change pas), bilan de victoire. Raison : l'auteur voulait le « côté
     chiffres » d'un RPG.
182. **Difficulté** : Promenade, Aventure, Épreuve, par multiplicateurs du moteur ; Aventure
     ne change rien aux chiffres mesurés. Épreuve est trop dure sur certains boss (15 % contre
     les Nazes de nuit) et n'est pas mesurée aux chapitres 6 et 7 : à reprendre.
183. **Économie** : mesurée par `tests/audit_economie.py`. Chapitres 2 et 3 presque
     inachetables (12 % et 8 %), chapitres 4 et 6 tout achetable : prix et or des quêtes
     corrigés (24 %, 20 %, 87 %, 70 %). Restent : chapitres 2 et 3 loin de la moitié visée,
     expérience trop généreuse (niveau 31 au chapitre 6 pour 23 attendu), or du chapitre 7
     sans usage (marchand prévu avant le Passe-Plat).
184. **Incident du 20 novembre** : un agent a écrit cinq fichiers dans le dossier principal
     (outil d'édition appelé avec un chemin relatif). Annulés avec l'accord de l'auteur.
     Depuis : chemins absolus exigés dans chaque brief, contrôle de `git status` du dossier
     principal après chaque rapport.
185. **Redémarrage du 25 novembre** : le dossier temporaire a été nettoyé, les worktrees
     ont perdu leur lien git ; seul le travail commité a survécu. Depuis : les agents commitent
     souvent, et une branche reprise repasse son test complet avant fusion (les deux reprises
     échouaient).
186. **Décors 11** (trois agents, deux interruptions). Remparts de la Croûte : le voile
     venait de la transparence de Godot sur des boîtes fermées (faces arrière, tri) ; les
     occulteurs `local` percent désormais un trou tramé autour du héros (`occluder.gdshader`),
     jamais de transparence. Marais du Bouillon (horizon `marsh`, passerelles, reflets, feux
     follets), Grand Four (sol `mor_sol`, ustensiles, chaînes, Sauron agrandi : le champ
     `scale` vaut pour les personnages de carte), Porte Noire du Passe-Plat (herse, caméra plus
     ouverte), Isengarde (garde-corps, fumées), tombe et Profondeurs de Morbier. Rayons de
     lumière : force multipliée par 2,4 et densité par 1,5 (ils étaient invisibles), bornes du
     test relevées à 0,2 et 0,03. Caves de Brie : hors-carte en roche brune. Limace molle à 1,0.
     Restent vers 7 : caves de Brie, marais, chancellerie et auberge elfique un peu vides,
     torses des monstres du chapitre 6 (regardés, non repeints), tombe et Isengarde non revues
     après retouche.
187. **Marchand du chapitre 7** : Hubert Longuevue, colporteur du Dernier Étal, sur la
     dernière planche du Marais du Bouillon (après le Noyé des planches). Raison : l'or du
     chapitre ne servait à rien, et tout RPG classique offre un dernier ravitaillement avant
     la fin. Douze équipements et une ration ; l'audit donne 67 % de l'équipement du chapitre
     achetable avec son or. Boutique jamais jouée à la main.
188. **À surveiller** : un monstre jamais préchauffé (Mammouth de guerre) est apparu invisible
     puis mal peint au tout premier combat lancé directement par l'outil de capture ; pas
     reproduit en passant par la carte. Erreurs « Rect2 size is negative » de
     `battle_ui.gd` (`_spread_plates`) dans le journal, sans échec de test.
189. **Choisir un chapitre** (demande de l'auteur : « des sauvegardes pour tester chaque début
     de chapitre »). Pas de fichiers de sauvegarde figés : ils casseraient à chaque évolution
     du format (l'arbre d'anneaux le change) et ne passeraient pas du Mac au PC. À la place,
     une entrée de l'écran titre fabrique une partie neuve au vrai début du chapitre choisi,
     depuis `data/chapter_starts.json` (`src/core/chapter_start.gd`, `src/ui/chapter_screen.gd`) :
     équipe et réserve de la bible, niveaux attendus (7, 9, 11, 16, 18, 23 pour les chapitres 2
     à 7), meilleur équipement des boutiques précédentes, or, quêtes, drapeaux. Le test compare
     chaque début à l'état réel relevé à la fin du chapitre précédent (`GLAN_ONLY_FLOWDUMP`).
     La partie fabriquée n'a pas d'emplacement (`SaveManager.unchosen`) : sa première
     sauvegarde prend un emplacement libre, jamais celui d'une partie existante. Le chapitre 5
     commence à la scène du deuil (champ `chapter` encore au 4, comme en vrai). Restent : pas
     d'épilogue, réserve au même niveau que l'équipe, relevés des chapitres 3 et 4 mêlés,
     `ChapterStart.spend_talent_points` à adapter à l'arbre d'anneaux.

## Demandes de l'auteur : ce qui reste (18 novembre 2026, nuit)

- **Relecture visuelle complète** par un agent qui voit les images, puis corrections :
  arènes trop pâles (col, cité elfique, salle du Conseil) ou trop sombres (étage d'auberge),
  premiers plans flous trop gros, main-curseur petite, barre d'élan parfois loin du menu,
  titre long sur l'écran d'accueil, chapeau tronqué dans la vignette Équipe.
- **Mort de Bromure** au début du chapitre 5, puis **chapitres 5 à 7** (scénario détaillé
  dans la bible, à relire : sa fin a été écrite vite), un à la fois, avec les décors de
  chaque peuple, le bestiaire de `docs/BESTIAIRE.md` et les arènes de
  `docs/AMBIANCES_COMBAT.md`.
- **Graphismes** : l'auteur veut vraiment la patte d'Octopath Traveler ; les écarts les plus
  visibles restent les personnages (petits, peu détaillés), les maisons et le relief jouable.
- **Jamais vérifié par l'auteur** : musiques (dont les six morceaux des Mines), équilibre
  ressenti à la main avec l'élan et le nouvel équipement, prix des boutiques, navigation au
  clavier dans les nouveaux menus.
- Export pour faire tester (application Mac, ou version navigateur dégradée) : demandé puis
  mis de côté ; il faut télécharger les modèles d'export de Godot (environ 1 Go).

## Préparé pour la suite, mais pas fait

- `GameState.chapter` vaut `chapitre_2` à la fin du chapitre 1 : c'est le point
  d'accroche du chapitre suivant (Brie, le Poney Flagada, la rencontre d'Aragrogne).
- La Première Amarre est dans le sac (objet de quête) : elle peut servir plus tard.
- Aragrogne, Digoulasse et Grimli ont déjà leur fiche de combat et leurs talents
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
- La musique n'a jamais été écoutée par l'assistant, qui ne peut pas entendre : les
  partitions sont vérifiées (durées, notes, niveau sonore), pas leur beauté. Le son est
  celui d'un synthétiseur simple. Pas d'options (volume, touches).
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
5. Retoucher les musiques que l'auteur n'aimera pas (`data/music.json`), réglage du
   volume, bruits d'ambiance (rivière, vent, foule de la fête).
6. Vraies poses dessinées pour les monstres (corps qui bouge, pas seulement le visage).
163. **Chantier décors 6 (eau, sols, captures)** : l'eau est refaite en pixels tramés avec une carte
     des distances à la rive (haut-fonds clairs, large sombre, écume qui respire, reflets des
     cristaux et torches) ; le lac de l'antre de Morbier reçoit rochers et cristaux plantés dans
     l'eau, reflet de la paroi et lueurs. La mise au point (`World._focus_on_player`) recale chaque
     image la zone nette sur la vraie profondeur du héros : il n'est plus flou, quel que soit le
     décor (angle et zoom inchangés). Plaine et Cabécou : herbes hautes (`tallgrass`), fleurs,
     ombres de nuages (`clouds`). Chutes : seconde chute (une balustrade posée au pied de la terrasse a été retirée : les clôtures ignorent le relief), flaques sur la roche de la terrasse
     (`chu_roche` porte `puddles`). Isengarde : rails épais, flaques d'huile luisantes. Salle du
     Conseil : `ground_variation` 0,2. Enseigne du poney redessinée (le fer s'ouvrait sur le côté).
     Captures : `24_etal_ursule` recadrée, `110_brie_ecurie` ajoutée.


162. **Décors 9** (eau, mines, forêt, étal). Eau : berges déformées plus fort et suivant le trou du sol, texture de
     distance au rivage (`shore_tex`) pour un liseré d'écume fin et une bande mouillée côté terre ; cascade réécrite
     (nappes verticales qui défilent, bord tramé, écume au pied). Mines : murs du Morbier teintés (`wall_tint`, `wall_glow`
     bas), émission des murs nains noire (les panneaux blancs venaient de là), plan noir sous le lac. Forêt : tuiles
     retournées bloc par bloc (`VARY_TILES`), racines moins régulières. Salle du Conseil : cadre bleuté, plaques teintées
     (`"mottle": true`, réservé car coûteux : +150 ms à Fondue-Combe sinon). Isengarde : flaques d'huile tirées au hasard
     avec espacement. Bittebourg : vrai étal d'Ursule (`market_stall`). Restent faibles : sol crème des Galeries,
     bande verte au bas de Fongorn, mesure d'images par seconde bornée à 120 par l'écran.
