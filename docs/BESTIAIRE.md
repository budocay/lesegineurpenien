# Bestiaire du Seigneur des Anneaux Péniens

Ce document répond à une demande de l'auteur (18 novembre 2026) : mettre dans le jeu les créatures et les peuples que le récit d'origine place à chaque endroit, **au moment de l'histoire où l'on y arrive**, avec **des noms toujours drôles**. Il couvre les chapitres 1 à 7, du plus proche au plus lointain, et dit pour chaque créature ce qu'elle est, à quoi elle ressemble, comment elle se bat et pourquoi son nom tient debout.

Il complète `docs/HISTOIRE.md` (qui fait foi en cas de contradiction) et sert de cahier des charges aux agents qui construiront les chapitres : une créature décrite ici s'ajoute dans `data/enemies.json`, `data/skills.json` et `data/animations.json` sans toucher au code, sauf mention contraire.

**Statuts.** `[EN JEU]` : déjà dans les données. `[À CRÉER]` : proposé ici, à construire. `[À RACCORDER]` : le chapitre 4 est construit en parallèle par un autre agent ; ses créatures sont proposées ici pour que le bestiaire soit complet, mais si l'agent du chapitre 4 a déjà fixé un autre nom ou un autre rôle dans le jeu, c'est le jeu qui fait foi, et cette page se corrige.

## Comment un nom est fabriqué

La règle de ton de la bible s'applique sans exception : **dans le monde, personne ne rit.** Un Ouroukandouille se prend pour une troupe d'élite ; un Naze Sommelier est un professionnel. Le rire est pour le joueur, et il doit venir sans effort.

1. **Le monde a faim.** Les premiers cartographes avaient faim, donc les noms de lieux et de peuples puisent dans la cuisine. Les créatures, elles, sont nommées par les gens du pays qui les croisent : leurs noms sont plus pratiques que savants.
2. **Trois ressorts, à alterner.** (a) Le **mot-valise** : un nom du récit d'origine fusionné avec un plat ou un ingrédient (*Ouroukandouilles*, *Gobelardons*, *Entremets*). (b) Le **métier pris au sérieux** : une fonction administrative ou de cuisine appliquée à un monstre (*Troll Affineur*, *Corbeau Contrôleur*, *Naze Sommelier*). (c) L'**expression figée prise au pied de la lettre** (*Dindons de la Farce*, *Piqûre de rappel*, *Boucaniers*). On n'en met pas deux du même ressort de suite dans une même rencontre : ce serait une liste de calembours, pas un bestiaire.
3. **L'étymologie défendable.** Chaque nom a une explication qu'un érudit du jeu pourrait donner sans rire (voir « Double sens » de chaque fiche).
4. **Le titre du jeu, en filigrane.** *Anneaux*, *alliance*, *annulaire*, *doigt*, *tenir*, *dur*, *mou*, *droit*, *garde-à-vous* : ces mots reviennent, jamais dits en clair, toujours dans une institution, un proverbe ou un grade pris très au sérieux. Le carnet complet est à la fin de la section « Scénario détaillé des chapitres 5 à 7 » de la bible.
5. **Jamais cru.** Aucun nom de créature ne contient un mot grossier, même coupé en deux ou lu à haute voix. (C'est pourquoi la piste « Ouroukouilles » n'est pas retenue : voir les questions pour l'auteur.)

## Gabarit d'une fiche

> **Nom** `[statut]`. *Ce qu'elle parodie* (décrit en mots). *Où et quand.* *À peindre* : silhouette, couleurs, détail drôle. *Combat* : rôle ; compétences ; faiblesse ; état infligé. *Bestiaire* : la ligne de description. *Double sens* : ce qui se cache. *Noms* : variantes classées, la meilleure en premier.

Les éléments sont ceux du jeu : tranchant, contondant, feu, foudre, plante, torpeur. Les états sont ceux de `statuses.json` : poison, sommeil, sonné, ramolli, englué, galvanisé, garde, ébranlé, provocateur, démoralisé, enfumé ; un état nouveau est signalé « (nouveau) ».

---

## I. Ce qui existe déjà (chapitres 1 à 3)

Recensement d'après `data/enemies.json`. Ces noms ne changent pas.

| Identifiant | Nom | Où | Ce que c'est | Rôle, état |
|---|---|---|---|---|
| `limace_molle` | Limace molle | Pré Couché | Première victime visible du Ramollissement | Lente, englue |
| `guepe_cidre` | Guêpe à cidre | Pré Couché | Insecte ivre de pommes tombées | Rapide, poison |
| `champignon_dormeur` | Champignon dormeur | Pré Couché | Champignon de pré, spores soporifiques | Sommeil |
| `epouvantail_avachi` | Épouvantail avachi | Pré Couché | Gardien de champ qui n'effraie plus | Ramolli |
| `grande_baveuse` | La Grande Baveuse | Pré Couché (mini-boss) | Limace « grande comme une barque » | Englue en zone |
| `frelon_bois` | Frelon des bois | Bois Penché | Cousin sauvage de la guêpe | Poison |
| `amanite_molle` | Amanite molle | Bois Penché | Champignon toxique affaissé | Nuage toxique |
| `sanglier_flapi` | Sanglier flapi | Bois Penché | Sanglier dont le Ramollissement a émoussé les défenses | Charge sans conviction |
| `vieux_solitaire` | Le Vieux Solitaire | Bois Penché (boss) | Gardien de la clairière du Chêne Penché | Piétinement |
| `grenouille_bouffie` | Grenouille bouffie | Roselière | Grenouille gonflée | Langue, croassement |
| `sangsue_roseaux` | Sangsue des roseaux | Roselière | Sangsue qui ponctionne | Vol de PV |
| `feu_follet` | Feu follet éteint | Roselière | Lumière de marais à bout de souffle | Feu faible |
| `crapaud_buffle` | Monseigneur | Roselière (boss) | Crapaud-buffle sur la passerelle | Gobage |
| `morfale_eclaireur` | Morfale éclaireur | Village, route de Brie | **Les orques** du récit d'origine | Couteau à pain |
| `morfale_goinfre` | Morfale goinfre | Village, route de Brie | Orque de la troupe, mangeur | Marmite, petit creux |
| `naze_fouineur` | Le Naze | Chapitre 1 (boss) | **Les spectres de l'anneau**, cavalier sans visage | Souffle ramollissant, cri |
| `rat_cave` | Rat de cave | Caves de Brie | Rongeur d'affinage | Grignote |
| `mouche_cave` | Mouche de cave | Caves de Brie | Mouche à fromage | Dard |
| `ver_fromage` | Ver de fromage | Caves de Brie | Asticot de gruyère | Bave |
| `moisi_bleu` | Moisissure bleue | Caves de Brie | Moisissure de persillé | Spores, remugle |
| `vacherin` | Le Vacherin | Caves de Brie (boss) | Fromage coulant gigantesque | Coulée, remugle |
| `chantecler` | Chantecler | Ferme de Brie (boss) | Coq qui ne se laisse pas ramollir | Cocorico |
| `gaston_grosbras`, `veuve_poignet` | Gaston Gros-Bras, la Veuve Poignet | Poney Flagada (duels) | Champions du bras de fer mou | Poigne de fer |
| `naze_aine`, `naze_cadet` | Naze de l'Est, Naze de l'Ouest | Poney Flagada (boss, nuit) | Deux spectres de l'anneau | Serrage, doigt glacé |
| `chamois_blase` | Chamois blasé | Col des Biscottes | Chamois qui a tout vu | Bond, dédain alpin |
| `marmotte_cols` | Marmotte des cols | Col des Biscottes | Marmotte d'altitude | Grignote |
| `taon_cols` | Taon des cols | Col des Biscottes | Taon de montagne | Dard |
| `parchemin_vivant` | Parchemin vivant | Archives | Chien de garde de papier | Coupure, déroulement |
| `tampon_zele` | Tampon zélé | Archives | Tampon échappé de la Chancellerie | Estampille |
| `mite_rayonnage` | Mite de rayonnage | Archives | Mite des registres | Dard |
| `moisissure_rayonnage` | Moisissure de rayonnage | Archives | Moisissure des vieux papiers | Spores |
| `gardien_archives` | Le Gardien des Archives | Archives (boss) | Gardien qui ne prête rien | Triple exemplaire |
| `sauron_vigueur` | Sauron | Prologue (boss) | Sauron en pleine Vigueur, il y a trois cents ans | Heures sup, regard |

**Remarques pour la suite.**

- La famille des **Morfales** est la colonne vertébrale du bestiaire : tous les chapitres en recroisent, avec des spécialités locales (voir plus bas).
- Les Nazes du chapitre 1 et du chapitre 2 sont trois des neuf. Il en reste six pour la suite : le Naze Suprême (chapitre 6) et cinq autres que l'on retrouve **au service** du banquet de Sauron (chapitre 7), ce qui donne la fin attendue de la bible (« les neuf petits anneaux » roulent hors des décombres) sans avoir à les croiser neuf fois.
- Les animaux « ramollis » (limace, guêpe, sanglier, grenouille) sont des **victimes** du Ramollissement, pas des monstres. À partir du chapitre 4, les créatures sont des **peuples** et des **bêtes de guerre** : elles n'ont plus rien de mou, c'est la nouveauté du chapitre 5.

---

## II. Les Morfales, famille complète

**Les Morfales** `[EN JEU]`. Les orques du récit d'origine : troupe de base de Sauron, innombrable et mal nourrie, aperçue de loin dès le chapitre 1. *Où :* partout, du chapitre 1 au chapitre 7, avec des spécialités selon les lieux. *À peindre :* silhouette large et voûtée, mâchoire en avant, tablier de boucher, couleurs sourdes (vert bouteille, cuir sale, rouge tomate éteint) ; le détail drôle est l'ustensile de cuisine qui sert d'arme (couteau à pain, marmite, louche, tire-bouchon). *Double sens :* *morfale* est un mot de pays pour « goinfre » : ces créatures ne se battent que pour manger, et les chefs promettent des « repas chauds » à l'arrivée.

Les spécialités à créer, par ordre d'apparition :

| Variante | Chapitre | Rôle | Compétences | Faiblesse, état |
|---|---|---|---|---|
| **Morfale de siège, échelier** | 6 | Attaquant de mur, lent, en nombre | *Coup d'échelle*, *Escalade* (frappe doublée si le mur est « escaladé ») | Tranchant ; ébranlé |
| **Morfale de siège, sapeur** | 6 | Détruit les défenses (réduit la garde de l'équipe) | *Sape*, *Galerie* (pose un piège qui explose au tour suivant) | Feu ; sonné |
| **Morfale de siège, marmiton** | 6 | Soutien : soigne les troupes, lance du bouillon | *Soupe de guerre* (soigne un Morfale), *Jet de bouillon* | Foudre ; ramolli |
| **Morfale de cuisine, plongeur** | 7 | Tank humide, laisse le sol glissant | *Éclaboussure*, *Plonge* (démoralise) | Feu ; englué |
| **Morfale de cuisine, saucier** | 7 | Buffeur : épaissit les alliés (garde) | *Liaison au beurre*, *Réduction* (feu) | Plante ; enfumé |

Le sergent de la troupe, **Uglouk** (chapitre 5), est décrit avec les Ouroukandouilles.

---

## III. Chapitre 4 : la route des monts et les Mines de Morbier `[À RACCORDER]`

*Le décor d'origine : une montagne qu'on ne passe pas, des loups à la nuit tombée, la porte d'une cité naine fermée sur un lac, des galeries, une salle immense, un pont au-dessus de rien.*

**Les Ouargues-Garous** `[À CRÉER]`. Les loups monstrueux des steppes, qui chassent en meute et servent de montures aux orques ; le récit d'origine les fait attaquer l'équipe à la tombée de la nuit, après la montagne manquée. *Où :* route des monts, chapitre 4, juste avant Morbier ; ils reviennent dans la plaine du Roquefort au chapitre 5. *À peindre :* grands loups gris-roux, échine pelée, une gamelle accrochée à la selle, un Morfale minuscule et farouche monté dessus (la cavalcade fait deux sprites : la bête et le cavalier, qui peut tomber). *Combat :* attaquant rapide en meute ; *Course en meute* (attaque à la suite, vitesse), *Hurlement de la faim* (démoralise l'équipe), *Morsure à la gorge* (saignement : poison) ; faiblesse feu, torpeur ; si le cavalier est vaincu d'abord, la bête perd sa « selle » et se bat plus mal mais plus fort (rage). *Bestiaire :* « Ils ont faim en permanence, et leur maître ne les nourrit jamais mieux : c'est la seule chose qu'ils lui reprochent. » *Double sens :* *ouargue* pour *warg* (grognement), *garou* pour le loup-garou, le tout prononcé par les paysans de la route comme un seul gros mot d'épouvante. *Noms :* 1. **Ouargues-Garous** (la piste proposée, la plus lisible à voix haute, deux syllabes de grognement et une de légende) ; 2. **Loups-Cervelas** (le cervelas est un saucisson, et ces loups n'ont pas de cervelle ; un cran plus bête) ; 3. **Louvoyards** (loup + louvoyer, parce qu'ils attaquent de biais ; plus discret, moins drôle).

**Les Gobelardons** `[À CRÉER]`. Les gobelins des mines, petits, nombreux, grouillants, qui sortent de partout dans les galeries. *Où :* chapitre 4, de la porte aux profondeurs ; ils sont l'ennemi standard de Morbier. *À peindre :* nains de dessous, grosse tête, oreilles en feuilles, peau luisante (couleur de lard), bardés de bandes de lard fumé en guise de cuirasse et de casque de fortune, un lardoir en guise de lance. Détail drôle : ils se grattent la tête sous le casque, toujours au mauvais moment. *Combat :* nuée, faible en solo, dangereuse en nombre ; *Coup de lardoir* (piqué), *Barde* (se bardent de lard : la garde monte pour un tour), *Lardage* (jet de graisse : englue) ; faiblesse feu (ils grésillent et fuient), tranchant ; état : englué. *Bestiaire :* « Ils ne sont pas méchants, ils sont nombreux, ce qui revient au même quand on est seul. » *Double sens :* *lardon* (petit morceau de lard) + *gobelin* ; en prime, *lardon* est aussi un mot du pays pour « petit ». *Noms :* 1. **Gobelardons** (le lardon est le plus petit morceau, et ils sont très petits et très nombreux) ; 2. **Gobe-Lards** (la piste proposée : plus clair, mais « gobe » appartient déjà aux grenouilles) ; 3. **Gobelins-Minute** (jeu de préparation rapide, plus faible).

**Le Troll Affineur** `[À CRÉER]`. Le troll des cavernes, lent, massif et peu futé, qui garde une chambre de Morbier et fait un vacarme en entrant. *Où :* chapitre 4, mini-boss de la chambre des comptes de Morbier ; revient en nombre plus bas. *À peindre :* peau gris-vert à pores ouverts, énorme tablier de toile cirée, un crochet de boucher dans une main, des planches de bois couvertes de petits fromages ronds à l'épaule : il s'en sert comme de masses. Détail drôle : il retourne ses adversaires toutes les trois attaques, comme on retourne une meule. *Combat :* tank offensif ; *Retournement* (sonne l'adversaire), *Saumurage* (frotte de sel : dégâts et démoralisé), *Mise en cave* (avale un allié : il disparaît deux tours, puis revient « affiné », plus fort ou plus faible selon le hasard) ; faiblesse foudre, feu ; état : sonné. *Bestiaire :* « Il garde la cave comme d'autres gardent un enfant : en le retournant et en le salant. » *Double sens :* l'*affineur* mûrit les fromages en cave ; le troll de caverne, dans le récit d'origine, est celui qui garde la caverne. *Noms :* 1. **Troll Affineur** (le métier, sérieux, drôle sans effort) ; 2. **Troll de Cave à Fromage** (la piste proposée : explicite, un peu long) ; 3. **Troll Gruyère** (parce qu'on lui trouve des trous : trop facile).

**Le Troll Raclette** `[À CRÉER]`. Le troll des montagnes, qui se fige en pierre au premier soleil. *Où :* route des monts (chapitre 4), à l'aube. *À peindre :* troll gris-bleu couvert de plaques de fromage durci aux épaules, arrêté dans le geste, à moitié figé si l'on tarde. *Combat :* massif ; *Fonte* (lance son corps chaud : feu), *Plaque brûlante* (renvoie les coups) ; faiblesse torpeur ; état : ramolli. S'il fait jour dans l'arène, il perd la moitié de ses PV en se figeant. *Bestiaire :* « Qui le croise à l'aube le trouve figé ; qui le croise à midi l'est aussi, de peur. » *Double sens :* la raclette se mange fondue, comme lui, et se fige aussitôt qu'on la laisse. *Noms :* 1. **Troll Raclette** ; 2. **Troll de Glace Chaude** ; 3. **Troll des Cimes**.

**Le Guetteur du lac** `[À CRÉER]`. La créature à tentacules qui garde la porte de la cité naine, dans le lac sombre, et que personne n'avait jamais vue avant d'y toucher. *Où :* chapitre 4, lac devant la porte de Morbier ; boss d'entrée. *À peindre :* un grand poulpe vert-de-gris dont n'émergent que les tentacules et un œil jaune ; les ventouses font des cercles réguliers sur chaque bras. Détail drôle : il tient la porte fermée et la rouvre dès qu'on dit le bon mot de passe. *Combat :* boss à bras multiples (quatre bras à frapper séparément, chacun avec sa jauge) ; *Enlacement* (englué), *Coup de ventouse* (aspire du mana), *Marée basse* (se retire, protégé, puis frappe) ; faiblesse feu, foudre ; état : englué. *Bestiaire :* « Les nains l'appellent le Seigneur des Anneaux, à cause des ventouses, et personne ne trouve cela drôle, surtout pas lui. » *Double sens :* c'est ici que le titre du jeu entre en scène : les **anneaux** de calamar. Nom prononcé le plus sérieusement possible par Grimli. *Noms :* 1. **le Guetteur du lac, dit le Seigneur des Anneaux** (le surnom est la blague, le nom officiel la garde) ; 2. **le Poulpe de Garde** ; 3. **le Calamar-Sentinelle**.

**Le Balourd** `[À RACCORDER, nom fixé par la bible]`. Le démon des profondeurs, flammes et ténèbres, qui garde le pont de Morbier. *Où :* chapitre 4, fin ; Glandoulf le retient sur le pont (« Vous ne passerez pas… ») et tombe avec lui. *À peindre :* géant d'ombre et de braise, cornes, fouet de flammes, mais **maladroit** : il bouscule tout. Détail drôle : un morceau du décor tombe toujours sur son pied. *Combat :* boss de deux phases (le pont, puis la chute) ; *Fouet de flammes*, *Bousculade* (renverse l'équipe), *Maladresse brûlante* (une attaque sur quatre touche un de ses alliés ou lui-même) ; faiblesse torpeur, foudre. *Bestiaire :* « Il est grand, il est ardent, il n'a jamais rien rattrapé. » *Double sens :* *balourd* : lourdaud, et *balourdise* : la maladresse qui se prend pour de la force. Rien à changer, le nom est bon.

**Goulûm** `[À RACCORDER, nom fixé par la bible]`. Le Grobitte qui a gardé l'anneau trois cents ans. Pêcheur Trempette de Bittebourg, jadis, rêvant du plus gros poisson. *Où :* chapitre 4 (duel d'énigmes, puis combat), puis fil conducteur des chapitres 6 et 7. *À peindre :* silhouette maigre, nue sous un chiffon, yeux immenses, doigts palmés ; il tient en bandoulière un filet vide et une canne sans hameçon. Détail drôle : il parle à son filet. *Combat :* duel d'énigmes (texte) puis combat rapide, esquive élevée ; *Bijou de famille* (invoque son envie : démoralise), *Cache-cache* (disparaît), *Coup de filet* (englué) ; faiblesse feu, tranchant. *Bestiaire :* « Le seul Grobitte du Comté à avoir voulu quelque chose. On voit ce que cela donne. » *Double sens :* *mon bijou de famille*, formule de la bible, que Goulûm prononce avec le plus grand sérieux (les bijoux de famille se transmettent).

**Les piquets de grève** `[À CRÉER, facultatif]`. Les nains de la dernière colonie de Morbier, encore en grève depuis quarante ans, devant la chambre qui leur est interdite. Pas ennemis : un dialogue et une quête possible (obtenir le passage contre trois revendications). *Nom :* **le Piquet de Morbier**.

---

## IV. Interlude : la Lothlorraine `[À CRÉER, léger]`

*Le décor d'origine : une forêt d'arbres aux feuilles d'or qui ne tombent pas, une dame qui voit loin, un miroir, des barques.*

**Les Reflets** `[À CRÉER]`. Dans le Miroir de Dame Galadrielle, chacun voit ce qu'il ferait de la Vigueur. Pour les trois héros qui y restent trop longtemps (Froton, Aragrogne, Merri), un combat léger oppose chacun à **son Reflet** : même sprite, aplati, teinté d'or, qui fait ce que le héros voudrait faire sans se fatiguer. *Combat :* même fiche que le héros, en miroir inversé (sa force, sa faiblesse), sans PV de départ complets : il suffit de lui montrer la sortie (*Retour à la raison*, un geste sans dégâts qui le dissout). *Nom :* **le Reflet Trop Content (de soi)**, ou plus court **le Reflet Content**. *Bestiaire :* « Il a tout ce que vous voulez et ne s'en lasse jamais. Il n'a pas de visage ; c'est le vôtre, avec moins de rides. »
---

## V. Chapitre 5 : le Roquefort et l'Isengarde-Manger

*Le décor d'origine : des plaines d'herbe haute et un château de bois doré sur une colline, une très vieille forêt dont les arbres ne sont pas tout à fait des arbres, une tour noire au milieu d'un cercle de fosses où l'on forge une armée.* Le Ramollissement du chapitre 1 était celui des bêtes ; ici, les ennemis sont **durs**, organisés, rentables. C'est la première fois que le jeu fait peur sans faire rire : le rire vient des noms et des détails.

### Ouroukandouilles `[À CRÉER]`

Les grands orques d'élite d'Isengard, plus grands, plus noirs, plus disciplinés que les orques ordinaires, qui supportent le jour et marchent sans s'arrêter. Dans le récit d'origine ils sont fabriqués en série dans des fosses. *Où :* embuscade des Chutes du Gratin, poursuite dans la plaine, Pétrins de l'Isengarde-Manger (chapitre 5) ; on en croise encore au chapitre 6. *À peindre :* nettement plus hauts que les Morfales, torse en tonneau, peau lie-de-vin, la **Louche Blanche** (emblème de Sarumâle) peinte sur la poitrine, plastron en tôle de four, casque en forme de marmite retournée. Détail drôle : ils sont *levés*, pas nés ; leur dos porte une croûte dorée, et ils craignent l'humidité. *Combat :* troupe de choc, trois spécialités : **de ligne** (bouclier en couvercle ; *Mur de couvercles*, garde pour deux tours ; *Coup de louche*) ; **brocheur** (lance à trois pointes ; *Tir à la brochette* : touche trois cibles à la suite) ; **pétrisseur** (sous-officier ; *Coup de pétrin*, *Montée en température* : galvanise ses voisins, *Remise au four* : relève un allié tombé une fois). Faiblesse : feu, mais s'ils sont mouillés ils se détrempent (foudre double) ; état : sonné. *Bestiaire :* « On ne les naît pas, on les lève. Ils sortent du four grands, bruns et obéissants, et on les trouve dans l'état où l'on voudrait trouver un pain. » *Double sens :* *Ouruk* (grand orque) + *andouille* (boudin farci) : une andouille est à la fois une charcuterie tassée et, par extension, un benêt ; les hommes d'Isengarde ne l'entendent que dans le premier sens. Le « levé, pas né » vient de ce que les Pétrins (fosses) sont des **pétrins** à pain, où la pâte lève. *Noms :* 1. **Ouroukandouilles** (ouruk + andouille ; le nom entier fait penser à un régiment, et les soldats entre eux disent « les Ouroukans », avec le plus grand sérieux) ; 2. **Ouroukailles** (ouruk + racaille, c'est l'orthographe que l'auteur lui-même a employée ; plus simple, moins culinaire, un peu plus loin du monde qui a faim) ; 3. **Gros-Morfales** (la piste proposée : sûre, mais elle dit seulement « plus gros » : sans jeu).

**Le sergent Uglouk** `[À CRÉER]` (mini-boss, chapitre 5, embuscade des Chutes du Gratin) et **le capitaine Grichnak** `[À CRÉER]` (mini-boss, plaine, chapitre 5). Le premier commande les Ouroukandouilles d'Isengarde, le second une troupe de Morfales du Mordgras venue réclamer « la livraison ». Ils se disputent les prisonniers (Isengarde veut les livrer à Sarumâle, le Mordgras à Sauron) : c'est la querelle d'une cantine contre un service, que le joueur voit de loin dans une scène. *À peindre :* Uglouk, large, la Louche Blanche en bandoulière, une cuillère en bois fendue pour sceptre ; Grichnak, maigre, nerveux, un menu graisseux sous le bras. *Combat :* Uglouk, *Appel de la gamelle* (convoque deux Ouroukandouilles), *Coup de louche*, *Rapport circonstancié* (note le héros le plus faible : tous les ennemis le visent un tour) ; Grichnak, vif, *Pince à saisir*, *Casse-croûte volé* (vole un objet et se soigne). *Double sens :* *Uglouk* se lit comme une cuisinière mal lunée (glouglou de marmite), *Grichnak* comme un casse-croûte volé à la sauvette (l'anglais *snack*, avec un grincement).

**Le Pâton** `[À CRÉER]`. La pâte d'Ouroukandouille qui n'a pas fini de lever, dans les Pétrins : ni méchante, ni dangereuse. *À peindre :* masse beige, informe, yeux en petits trous, qui se gonfle quand on la regarde. *Combat :* aucun, ou presque : elle gonfle jusqu'à éclater (*Levée soudaine*, inflige des dégâts au héros qui la touche). *Annexe :* Sam peut les cuire en brioches, ce qui désarme la fabrique (voir la quête « Pas de levain, pas de guerre »). *Nom :* **Pâton**. *Bestiaire :* « Mange-le avant qu'il ne te mange. Ou laisse-le gonfler : il est de bonne composition. »

### Les Ouargues-Garous (reprise)

Les mêmes loups qu'au chapitre 4, dans la plaine, pour une chasse de nuit : même fiche. Au chapitre 5, ils s'attaquent aussi aux **brebis de guerre** des Cavaliers, ce qui sert de prétexte à une rencontre où Éomèche et les siens interviennent.

### Le Corbeau Contrôleur `[À CRÉER]`

Les corbeaux qui espionnent pour Sarumâle, grands, noirs, sans plume de queue, avec un cercle de lunettes sur le bec. *Où :* ciel du Roquefort, Fongorn, aux abords de l'Isengarde-Manger. *À peindre :* un corbeau à lunettes carrées, un bloc-notes à la patte. Détail drôle : il note les héros, et on le voit hocher la tête. *Combat :* **ne se bat guère** ; si on le laisse, il *envoie son rapport* et la rencontre suivante est plus dure ; *Becquetée*, *Rapport circonstancié* (comme Uglouk) ; faiblesse foudre, tranchant ; état : démoralisé. *Bestiaire :* « Il vous voit, il vous note, il vous transmet. Ce n'est pas du vice, c'est de la conscience professionnelle. » *Double sens :* le corbeau « contrôleur » est un inspecteur du travail à plumes (*contrôleur* de train, de gestion) ; le corbeau d'origine surveille pour son maître. *Noms :* 1. **Corbeau Contrôleur** ; 2. **Corbeau d'Inspection** ; 3. **Corbeau de Service**.

### Les Hirsutes de Dunlande `[À CRÉER]`

Les hommes sauvages des collines, menés par Sarumâle, qui descendent dans le Roquefort pour y piller : barbus, rudes, en peaux de bête, qui brandissent des gourdins. *Où :* plaine du Roquefort et abords de Cabécou, chapitre 5 ; ils reviennent en renfort d'une rencontre à l'autre. *À peindre :* cheveux hérissés, barbes tressées de paille, gourdins taillés dans des chênes, peaux de brebis tachées. Détail drôle : les peaux de brebis sont celles qu'ils ont volées aux Cavaliers, avec encore la marque de fabrique. *Combat :* masse physique, *Gourdin de bûcheron*, *Cri de colline* (galvanise), *Pillage* (vole une pièce d'équipement non équipée) ; faiblesse feu, torpeur ; état : sonné. *Bestiaire :* « Pas méchants, juste mal élevés. Surtout, ils ont de bonnes raisons d'être en colère : on ne leur a jamais demandé leur avis. » *Double sens :* *hirsute* (poilu et brouillon) pour le peuple de la colline, dont le nom d'origine évoque la dune. *Noms :* 1. **Hirsutes de Dunlande** ; 2. **Barbares de la Dunelande** ; 3. **Dunois-Sauvages** (le premier est le plus drôle sans effort, le troisième jouerait sur le *Dunois* historique).

### Grimace Langue-de-Bois `[À CRÉER]`

Le conseiller du roi Théodort, qui a l'oreille du souverain et l'a endormi à force de belles paroles. *Où :* château de Cabécou (la Bergerie d'Or), chapitre 5 ; boss de transition. *À peindre :* long, pâle, gilet de laine grise trop boutonné, manches bordées de fourrure de brebis, un parchemin roulé toujours à la main, la langue un peu trop épaisse. Détail drôle : il parle en détachant chaque mot de façon à ne jamais finir. *Combat :* **boss de parole** : *Langue de bois* (endort toute l'équipe), *Éléments de langage* (renvoie la question à l'envoyeur : esquive), *Dans le cadre de…* (soigne l'allié le plus abîmé), *Motion de défiance* (démoralise) ; faiblesse : les phrases courtes (toute attaque *Ordre bref* ou *Remarque blessante* lui coûte double) ; il est battu quand on lui coupe la parole trois fois. *Bestiaire :* « Il a dit trois cents mots, personne n'a rien retenu, et le roi s'est endormi. C'est ce qu'on appelle une politique. » *Double sens :* la *langue de bois* est le discours officiel qui dit sans rien dire ; la bible a fait de lui le Langue-de-Vipère de l'histoire d'origine, avec une langue de bois. *Noms :* 1. **Grimace Langue-de-Bois** (fixé par la bible) ; en surnom : « l'Éloquent » ; en variante de titre : « le Chargé de la Parole du Roi ».

### Les Entremets, Barbe-Molle et les Hors-d'œuvres `[À CRÉER]`

Les arbres qui marchent et leurs bergers : une forêt ancienne dont certains arbres ont l'esprit, la parole lente, et qui mettent des jours à décider quoi que ce soit ; d'autres, moins sages, se lèvent d'un bloc quand la colère monte. *Où :* forêt de Fongorn (chapitre 5, la forêt voisine de l'Isengarde-Manger) ; marche sur l'Isengarde en fin de chapitre. *À peindre :* **les Entremets** : géants de bois noueux, mi-arbre mi-vieux monsieur, barbe de mousse, yeux de résine, qui parlent d'un souffle de vent ; **Barbe-Molle**, le plus vieux, sa barbe tombe jusqu'aux genoux et y a pris racine ; **les Hors-d'œuvres**, des arbres plus petits, vifs, aux branches en bras, qui avancent par saccades. Détail drôle : les Entremets ne disent jamais bonjour, ils s'enracinent d'abord, par politesse. *Combat :* **alliés** plutôt qu'ennemis : *Marche des Hors-d'œuvres* (invocation unique : trois arbres frappent au hasard), *Bois de lit* (barbe-Molle protège l'équipe) ; en ennemis, **les Hors-d'œuvres égarés** (arbres furieux de Fongorn, un peu plus loin du chemin) : *Coup de branche*, *Étreinte d'écorce* (englué) ; faiblesse feu, tranchant. *Bestiaire :* « Les Entremets sont lents mais ne reculent pas. Les Hors-d'œuvres sont vifs et reculent encore moins. » *Double sens :* l'*entremets* est le plat entre le service principal et le dessert, celui qui prend son temps ; les *hors-d'œuvres* sont servis avant, par petites assiettes qui arrivent toutes ensemble : voilà l'armée d'arbres (la nuance de rythme est le jeu). *Noms :* 1. **Entremets** pour les bergers, **Hors-d'œuvres** pour les arbres qui marchent (le couple est le plus propre) ; 2. **Gros-Plats** et **Amuse-Bouches** (un cran plus drôle, moins étymologique) ; 3. **Barbus** et **Branchus** (plus simple, mais sans cuisine).

### Sarumâle le Blanc `[À CRÉER, nom fixé par la bible]`

Chef de l'Ordre des Mages, maître de l'Isengarde-Manger, qui veut l'anneau pour « enfin obtenir des résultats ». *Où :* tour de l'Office, Isengarde-Manger (chapitre 5) ; boss de fin de chapitre. *À peindre :* long manteau blanc immaculé (qu'on voit se tacher en cours de combat), barbe soignée, col bien droit, une **louche blanche** en guise de bâton, un tableau de service à la main. Détail drôle : sa robe change de couleur au fil des phases (blanc, crème, puis « blanc cassé » jusqu'à la défaite, qui lui laisse une robe bariolée). *Combat :* deux phases ; *Réunion de service* (convoque : un héros, à son tour, est **Convoqué (nouveau)** : il perd son tour et revient avec un malus de fatigue), *Rendement* (galvanise ses troupes), *Coup de louche blanche* (gros dégâts de foudre), *Voix de Sarumâle* (confond un héros qui se met à viser ses amis un tour), *Mirette* (révèle la faiblesse de toute l'équipe aux ennemis) ; en seconde phase (après l'inondation des Pétrins), *Heures supplémentaires* (comme Sauron) et *Dossier Glandoulf* (affiche la faute du mage, démoralise Glandoulf seul tant qu'il n'a pas répondu). Faiblesse : torpeur (il ne dort jamais, ce qui rend la torpeur très efficace), foudre faible ; états : sonné, démoralisé. *Bestiaire :* « Il ne veut pas le pouvoir, il veut les résultats. On voit où cela mène. » *Double sens :* le Blanc de l'Ordre contre le Blanc Cassé de Glandoulf (qui est une couleur de peinture) ; *Sarumâle* garde sa syllabe de trop. Rien à changer.

### Froton Anneauté `[À CRÉER]`

Combat contre Froton lui-même, dans la cellule du Garde-Manger, quand il enfile l'anneau. *À peindre :* le sprite de Froton, translucide, doré, avec un halo de chaleur ; ses compagnons vus à travers lui. *Combat :* jauge de **Serrage** à faire descendre (voir `docs/HISTOIRE.md`, mécaniques) : il frappe vite (*Coup de volonté*), s'efface (*Invisible* : 60 % d'esquive), reste insaisissable sans appel à la raison ; les actions de **Sam** (*Soupe du jour*), de **Merri** (*Plan bien ficelé*) et de **Pépin** (*Antidote maison*) lui retirent du Serrage. Il n'est pas tué : à zéro, il lâche l'anneau. *Bestiaire :* « Il s'est trouvé tout seul, très fort, sans un seul ami à portée de voix. »

### L'Aigle Grosse-Plume `[À CRÉER, personnage]`

L'aigle géant du récit d'origine, qui sauve Glandoulf et plus tard toute l'équipe. *Où :* chapitre 5 (il dépose Glandoulf à Fongorn), dernier chapitre (il évacue la Montagne). *À peindre :* aigle de la taille d'une charrette, brun doré, un brassard de la **Compagnie des Aigles, Service des colis non réclamés** à l'aile. *Bestiaire :* « Il ne vient que s'il y a une demande. Une demande est une feuille avec trois exemplaires. » *Double sens :* le gag de la bible, « personne n'avait rempli le formulaire ». *Noms :* 1. **Aigle Grosse-Plume** ; 2. **Aigle de Service** ; 3. **Aigle Rapport**.

---

## VI. Chapitre 6 : Minas Tartine et les champs du Pelle-à-Tarte

*Le décor d'origine : une cité blanche en sept niveaux adossée à une montagne, un immense champ de bataille devant, une armée de morts qui répond à un serment, des pirates sur le fleuve, des éléphants de guerre, un cavalier sans visage sur une bête ailée qui plane au-dessus de la bataille.* Ici, la menace est **massive** : c'est la grande bataille du jeu.

### Gothmoque, lieutenant de Minas Moisie `[À CRÉER]`

Le lieutenant qui mène l'armée de Mordgras au siège, ancien capitaine d'une cité tombée aux mains des Nazes (Minas Moisie, la ville morte). *Où :* siège de Minas Tartine, chapitre 6 ; mini-boss de la Grande Porte. *À peindre :* armure sombre à bord vert-de-gris, casque à cimier de moisissure bleue, grande trompe de cuivre ; sa voix sonne comme du métal froid. Détail drôle : il parle dans sa trompe et on ne comprend pas un mot. *Combat :* *Sonnerie de cors* (galvanise tous les Morfales), *Ordre de marche* (avance l'ordre des tours des ennemis), *Coup de hallebarde*, *Moquerie* (démoralise) ; faiblesse foudre ; état : sonné. *Bestiaire :* « Il commande très bien, du moment qu'on ne lui demande pas de se faire comprendre. » *Double sens :* *gothique* (cité gothique, cité noire) et *moque* (il se moque), avec un air de *Gothmog* du récit d'origine. *Noms :* 1. **Gothmoque** ; 2. **Gothmouille** ; 3. **Gothmoche**.

### La Grondine `[À CRÉER]`

Le bélier de siège de l'armée de Sauron, long et lourd, tête de forme étrange qu'on traîne jusqu'à la Grande Porte. *À peindre :* une énorme baguette de pain de fer, tête de loup à l'extrémité (le nom est la partie la plus sérieuse), tirée par deux trolls ; on la voit s'ébrécher à chaque coup. *Combat :* machine à abattre en cinq coups de bélier ; on gagne en **la brûlant** (feu) ou en abattant ses tireurs avant le dernier coup (sinon la Grande Porte tombe et la scène change). *Bestiaire :* « On l'appelle la Grondine parce qu'elle gronde. Elle n'est pas tendre pour les portes. » *Double sens :* *baguette* (pain, et bâton), et le bélier d'origine, *Grond*. *Noms :* 1. **la Grondine** ; 2. **la Grande Baguette** ; 3. **le Bélier Croustillant**.

### Les Dindons de la Farce `[À CRÉER]`

Les montures ailées des Nazes : de grandes bêtes noires qui planent au-dessus des armées et qui piquent d'un coup. *Où :* siège de Minas Tartine et champs du Pelle-à-Tarte, chapitre 6 ; le Naze Suprême en monte une ; boss : **Le Dindon du Naze Suprême**. *À peindre :* plumage noir mité, tête de vautour et gorge fripée de dindon, ailes de cuir, des ergots de coq, une paire de **lunettes de brocanteur** accrochée au bec (détail drôle). *Combat :* attaquant aérien ; *Piqué de dinde* (gros dégâts, hors de portée tant qu'il vole), *Glouglou glacial* (cri qui démoralise), *Chute en piqué* (écrase l'équipe, ne peut le faire que depuis le ciel) ; il faut le faire descendre (foudre, flèches de Digoulasse, les *Doigts de fée* de Froton) ; faiblesse foudre, tranchant ; état : démoralisé. *Bestiaire :* « On l'appelle dindon parce qu'il est la victime toute désignée : il est toujours celui qu'on voit en premier. » *Double sens :* *le dindon de la farce* est celui qui reçoit tous les coups ; ici, il les donne, sans cesser de les prendre. Le mot *farce* est aussi la préparation qu'on met dans le dindon : une farce, en cuisine. *Noms :* 1. **Dindons de la Farce** (l'expression figée prise au pied de la lettre, dans le sérieux de l'état-major) ; 2. **Corneilles de Naze** (neutre, sans jeu) ; 3. **Ptéro-Dindes** (jeu de science-fiction, le moins bon).

### Le Naze Suprême `[À CRÉER, nom fixé par la bible]`

Le chef des neuf, le plus ancien des rois à qui Sauron offrit un petit anneau trop serré, qui mène les Nazes. *Où :* chapitre 6, fin de la bataille ; boss de chapitre. *À peindre :* silhouette de géant en armure noire, cape fendue, couronne de fer fendue en deux par une fissure très ancienne ; il ne porte pas de visage mais une grille de heaume ; le **petit anneau** qui l'étrangle est visible à son doigt gauche (l'annulaire). Détail drôle : le doigt de l'anneau est enflé, bleu, et il le masse en cachette quand il croit qu'on ne le voit pas. *Combat :* boss à deux phases (sur sa bête, puis à pied) ; *Lame de Minas Moisie* (gros dégâts), *Heure de la fermeture* (tout l'écran s'assombrit, les soins sont divisés par deux), *Cri strident* (comme les autres Nazes), *Serrage collectif* (touche toute l'équipe : ralentit). **Mécanique propre :** **« Nul homme du Gouda ne me terrassera »** : les dégâts d'Aragrogne (et de tout humain) sont réduits à 1 ; ce sont les Grobittes, les nains, les elfes et la dame Éolaine qui le blessent. Il se retourne vers Aragrogne dès que celui-ci le *provoque* : il tourne alors le dos à tout le reste de l'équipe, et un *Coup dans le dos* de Merri fait des dégâts énormes. Faiblesse : torpeur, feu ; état : sonné. *Bestiaire :* « Il règne depuis un temps qu'il ne compte plus, sur un trône qu'il n'a jamais quitté, avec un petit anneau qui le serre depuis trois cents ans. Il a de quoi être de mauvaise humeur. » *Double sens :* le petit anneau est porté **à l'annulaire**, et le Naze Suprême est « suprême » comme le sont les sauces ; et la prophétie d'origine (« aucun homme ne me tuera ») se retourne en règle de jeu.

### Les Éveillés, l'armée des morts `[À CRÉER]`

L'armée des morts qui avaient prêté serment à Isidur et ne l'ont pas tenu, maudits jusqu'à ce qu'ils s'acquittent. *Où :* le Sentier des Insomniaques, au pied du Mont Sans-Sommeil, puis le fleuve, puis les champs du Pelle-à-Tarte, chapitre 6. **Variante de la bible :** la dette n'est pas une lâcheté mais un **sommeil** : ils avaient juré de venir, ils sont restés au lit, et le roi les a condamnés à ne plus jamais dormir (Isidur, qui ensuite ne dormira plus lui non plus). *À peindre :* fantômes verdâtres en armures d'un autre âge, mais surtout **les yeux grands ouverts, cernés de violet**, la silhouette un peu voûtée de ceux qui n'ont pas dormi depuis trois siècles. Détail drôle : ils portent un petit bonnet de nuit sous le casque, tricoté mais inutile. *Combat :* ils sont d'abord **ennemis** (le Sentier, quatre rencontres) puis **alliés** (une invocation unique à la bataille, *Appel des Éveillés* : ils balayent trois lignes d'ennemis). Ennemis : *Veille forcée* (insomnie : empêche de récupérer du mana ce tour-ci : **Insomnie (nouveau)**), *Cauchemar éveillé* (démoralise), *Appel du lit* (draine la force) ; faiblesse **torpeur** (ils en rêvent) ; ils ne sont pas détruits mais **s'endorment** quand leurs PV tombent, l'un après l'autre, sur le sol, avec un soupir. *Bestiaire :* « Ils ne demandent qu'une chose : qu'on les laisse dormir. En échange, ils ne vous demandent presque rien : seulement de les faire taire. » *Double sens :* *éveillés* à la fois les morts qui n'ont plus de repos et ce que le jeu appelle la Vigueur. *Noms :* 1. **les Éveillés** (court, sobre, inquiétant, et le contraire de tout ce qu'on attend d'un mort) ; 2. **les Insomniaques** (précis, un peu plus pesant, titre du sentier) ; 3. **les Veilleurs du Rond-Pré** (le plus poétique, le moins drôle).

**Le Roi des Éveillés** `[À CRÉER]` (mini-boss du Sentier). Ancien chef de guerre, grand, en cape effilochée, les mains croisées sur une épée dont la poignée est une plume d'oreiller. *Combat :* 3 000 PV, il se défend de ne pas dormir : *Veille forcée*, *Cauchemar éveillé*, *Dernier mot* (inflige à Aragrogne le reproche de son ancêtre). **Il ne peut être vaincu que par un acte** : après sept tours, la commande unique d'Aragrogne, *Par décret : dormez* (version spéciale de *Par décret*), l'achève sans un point de dégâts. *Bestiaire :* « Il avait juré d'être là. Il y est, depuis trois siècles. Il n'a jamais été aussi fatigué. »

### Les Boucaniers d'Ombrine `[À CRÉER]`

Les pirates du Sud, alliés de Sauron, qui remontent le fleuve en voiles noires pour prendre la cité à revers. *Où :* port de Port-Salé et fleuve, chapitre 6 ; ils sont **détournés** par Aragrogne et les Éveillés, qui prennent leur flotte. *À peindre :* chemises rayées, foulards sales, anneau d'oreille de la taille d'un bracelet (détail drôle), bottes de cuir graissé, sabres d'abordage, voiles faites de torchons noirs cousus main. Détail drôle : leur drapeau, une tête de poisson sur des pelles croisées. *Combat :* attaque rapide, rhum à bord ; *Abordage* (attaque en groupe), *Rhum du bord* (galvanise soi-même, mais ensuite démoralisé), *Coup de grappin* (attire le héros vers lui, changement d'ordre) ; faiblesse feu, foudre ; état : sonné. *Bestiaire :* « Ils pillent avec méthode, et ils se partagent le butin à l'unité, comme des honnêtes gens. » *Double sens :* *boucan* est le fumoir d'où vient *boucanier* ; *Ombrine* est un poisson de la côte, et l'ombre des voiles. *Noms :* 1. **Boucaniers d'Ombrine** ; 2. **Forbans de la Marée-Basse** ; 3. **Corsaires du Bar** (piste : *un bar*, de sorte que *Umbar* se prononce *un bar*).

**Le capitaine Saumure** `[À CRÉER]`, chef de la flotte pirate. Grand, peau tannée, barbe goudronnée, un hareng saur en guise de plume au chapeau. *Combat :* *Saumurage* (démoralise), *Salve de hareng* (dégâts en zone), *Tonneau de poudre* (gros dégâts, une fois) ; faiblesse foudre, feu. *Bestiaire :* « On dit qu'il est parti à la mer pour fuir une dette. La mer a fini par la lui réclamer, mais il a bonne tenue. »

### Les Hommes du Cassoulet et les Mammous `[À CRÉER]`

Les hommes du lointain Sud, qui ont rallié Sauron, montent des **éléphants de guerre** couverts de tours. *Où :* champs du Pelle-à-Tarte, chapitre 6. *À peindre :* **les Cassoulétains** : archers et lanciers en tunique rouge brique, turban de toile à sac, boucliers en couvercle de faitout, peau cuite comme une croûte ; les **Mammous** : mammouths géants, laineux, à la peau molle (le Ramollissement les a rendus mous mais énormes), chacun avec une tour de bois couverte de petits archers et des défenses cerclées de fer. *Combat :* **Cassoulétain** : *Pluie de haricots* (flèches en zone), *Coup de lance*, *Marche forcée* ; faiblesse feu, foudre ; **Mammou** : géant, 4 000 PV, *Piétinement de masse*, *Trompe-la-faim* (inflige démoralisé), *Chute de tour* (l'archer le plus fort descend, joue un tour de plus) ; faiblesse tranchant (on lui coupe les jarrets), torpeur ; état : ramolli. *Bestiaire :* « L'éléphant, c'est un mammouth qui a perdu ses poils et gagné en importance. Le Mammou, c'est autre chose : il n'a rien perdu, il est seulement plus mou. » *Double sens :* *Mammou* est mammouth + *mou* (c'est le mot-clé du Ramollissement) ; *Cassoulet*, plat du Sud lent à mijoter, désigne le pays d'où ils viennent. *Noms :* 1. **Mammous** pour les bêtes, **Hommes du Cassoulet** pour leurs maîtres ; 2. **Mastodondes** et **Sudistes** (plus long, plus neutre) ; 3. **Grosses Bêtes de Sud** et **Haricotiers** (le moins bon).

### Personnages non combattants du chapitre

- **Dénigror, Intendant du Gouda** `[À CRÉER]` : père de Bromure, régent de Minas Tartine, qui dénigre tout, y compris les armées qui le sauvent. *Noms :* 1. **Dénigror** (*dénigrer* + le nom de l'Intendant d'origine) ; 2. **Dénétor** ; 3. **Dénigrard**.
- **Dame Éolaine** `[À CRÉER]` : cavalière du Roquefort, nièce du roi, qui tient tête au Naze Suprême ; invitée de combat pour la bataille. Son nom joue sur la laine.
- **Éomèche** `[À CRÉER]` : neveu du roi, banni par Grimace pour « excès de zèle ».
- **Les brebis de guerre** `[À CRÉER]` : montures des Cavaliers de Roquefort, laineuses, plus costaudes qu'elles n'en ont l'air, qui ne chargent qu'à l'heure de la traite.

---

## VII. Chapitre 7 : le Mordgras

*Le décor d'origine : un marais où flottent les visages des morts, une immense porte noire que l'on ne force pas, un col étroit avec une grotte-toile où vit une araignée géante, une plaine de cendres sous une tour surmontée d'un œil, une montagne de feu au bout de milliers de marches.* Ici le Ramollissement s'inverse : autour de Sauron, tout est **raide**, surchauffé, rentable. Les créatures sont donc **dures et infatigables**, jamais molles : elles ne dorment pas.

### Les Noyés du Bouillon d'Onze Heures `[À CRÉER]`

Les visages de morts qui flottent dans le marais, sous la surface, aux yeux ouverts : ils ont voulu rejoindre leurs morts de la guerre ancienne et s'y noient encore. *Où :* marais, chapitre 7, début ; les héros les croisent en suivant Goulûm sur des planches. *À peindre :* visages bleu-verdâtre, sous l'eau, cheveux d'algues, yeux fixes ; seule une main émerge pour saisir. Détail drôle : leur « bouillon » est un potage de poireaux qui bout, de loin, à feu doux. *Combat :* ils ne se montrent que si l'on **regarde** l'eau (l'équipe doit marcher sans lever les yeux : choix du joueur) ; *Regard trouble* (endort), *Main qui prend* (englue, retire un héros du combat tant qu'on ne l'a pas libéré), *Appel de la soupe* (drain de mana) ; faiblesse feu, foudre ; état : sommeil. *Bestiaire :* « Ils ne méritent pas un nom : ils s'en sont perdu un dans la soupe. Autant les appeler comme elle. » *Double sens :* *bouillon d'onze heures* est l'ancien nom d'une boisson empoisonnée ; elle appelle ici les morts à boire. *Noms :* 1. **les Noyés du Bouillon** ; 2. **les Visages de la Soupe** ; 3. **les Défunts du Marécage**.

### La Bouche du Maître `[À CRÉER]`

Le porte-parole de Sauron, qui parlemente à la Porte Noire. Dans le récit d'origine il n'est plus qu'une bouche : il ne dit rien de lui-même. Ici : le **maître d'hôtel** du Grand Œil. *Où :* le Passe-Plat (la Porte Noire), chapitre 7 ; boss de parlementaire. *À peindre :* grande silhouette sombre dont le visage disparaît sous un capuchon à bords noirs ; seules ses **lèvres** (pleines, souriantes, très luisantes) sortent, avec une serviette blanche sur le bras et un plateau d'argent. Détail drôle : il présente les conditions de reddition comme une carte de restaurant. *Combat :* **boss de parole** ; *Menu du jour* (trois offres de reddition ; refuser les trois suffit), *Addition* (dégâts proportionnels à l'argent que porte l'équipe : on peut les réduire en payant un **pourboire** de 100 écus), *Suggestion du chef* (confond), *Dessert* (coup final : une assiette qui explose) ; faiblesse torpeur, tranchant ; état : démoralisé. *Bestiaire :* « Il ne dit que ce qu'on lui a écrit. Il le dit si bien qu'on se demande qui l'a écrit. » *Double sens :* le *maître* est le maître de Sauron et le *maître d'hôtel* : la bouche d'un maître de maison. *Noms :* 1. **la Bouche du Maître** (maître d'hôtel de Sauron) ; 2. **le Chef de Rang** ; 3. **la Grande Gueule** (le moins élégant).

### Les Ologrills `[À CRÉER]`

Les trolls d'élite de Sauron : plus grands, plus noirs, qui supportent le soleil que craignent les autres trolls. *Où :* Passe-Plat et plaine de Gorgonzola, chapitre 7. *À peindre :* peau noire et luisante, comme croûtée à la poêle, des traces de quadrillage sur les épaules (le détail drôle : on y voit les barreaux d'un gril), une fourchette de cuisine géante à la ceinture. *Combat :* massifs, 6 000 PV ; *Saisie* (une attaque de feu à une cible, qui brûle ensuite), *Retournement* (comme le Troll Affineur) ; ils sont **insensibles au feu** ; faiblesse foudre, torpeur ; état : ébranlé. **Le Grand Ologrill** est le chef de l'armée devant la Porte, couvert de piques de fer. *Bestiaire :* « Les trolls ordinaires se changent en pierre au soleil. Les Ologrills n'y voient qu'une cuisson supplémentaire. » *Double sens :* *olog* + *grill* ; on les cuit pour les rendre solides. *Noms :* 1. **Ologrills** ; 2. **Trolls Saisis** ; 3. **Trolls Rôtis**.

### L'Arachnée `[À CRÉER, nom fixé par la bible]`

L'araignée géante du col, gardienne de la grotte-toile qui précède les cuisines. *Où :* col de l'Arachnée, chapitre 7. La bible : elle « tisse sans jamais s'arrêter et n'a pas dormi depuis des siècles ». *À peindre :* araignée énorme, velue, brun et vert sombre, huit yeux cernés de cernes mauves, trop de fils autour d'elle, un lacet de ruban dans chaque patte ; elle porte un petit bonnet de dentelle sur le cou (détail drôle : elle l'a tricoté). *Combat :* boss à deux phases ; *Toile sans fin* (englue toute l'équipe), *Piqûre de rappel* (poison en trois temps), *Point de croix* (frappe en croix, deux cibles), *Couture serrée* (immobilise un héros pour deux tours). **Mécanique :** elle est **immunisée contre le sommeil** tant que sa jauge de **Fatigue (nouveau)** n'est pas pleine ; chaque action qu'elle fait la remplit un peu ; à pleine jauge, la berceuse de Sam (*Chant de Sam* : quatre couplets, un par tour) l'endort pour de bon. On ne la tue pas : on l'endort, et elle dort enfin. Faiblesse feu, tranchant ; état : englué. *Bestiaire :* « Elle n'a pas fermé l'œil depuis la fin de l'autre monde. On l'a longtemps prise pour méchante. Elle est seulement fatiguée. » *Double sens :* *l'arachnée* (arachnide) *tisse* ; la *piqûre de rappel* est un vaccin, ici un poison qui revient. Nom déjà fixé. *Autres :* **les Fileuses**, ses petites araignées de col (*Fil à la patte* : englue ; très petites, très nombreuses ; faiblesse feu).

### Les Nazes du Service `[À CRÉER]`

Les cinq Nazes qui restent sont, au banquet perpétuel, **employés** : les anciens rois sont devenus la brigade de salle. *Où :* Salle du Banquet, chapitre 7, après les cuisines ; combat de brigade. *À peindre :* capes noires de leur grade, mais **en livrée** : nœud papillon blanc au col, tablier de grande maison, gants blancs, plateau à la main. Chacun porte, à l'annulaire gauche, son petit anneau qui le serre ; sur la livrée, une plaque porte le titre. Détail drôle : ils se saluent en s'inclinant exactement du même angle. *Combat :* cinq adversaires, combattus à la suite ou ensemble selon la difficulté :

- **Naze Sommelier** : *Dégustation* (draine des PV), *Bouchonné* (poison) ; faiblesse feu.
- **Naze Tranchant** : *Découpe* (trois coups à la file sur trois cibles), *Pièce de bœuf* ; faiblesse contondant.
- **Naze Plongeur** : *Éclaboussure sale* (démoralise), *Vaisselle brisée* ; faiblesse foudre.
- **Naze Pâtissier** : *Flambage* (feu en zone), *Pâte à choux* (englue) ; faiblesse torpeur.
- **Naze Maître de Salle** : *Placement* (inverse l'ordre de jeu), *Signal du maître* (galvanise les autres Nazes) ; faiblesse tranchant.

*Bestiaire :* « Ils servent le Maître depuis le jour où il leur a promis qu'ils ne serviraient plus. » *Double sens :* le titre de **maître de salle** et le service de table, pris avec un sérieux de haute cuisine ; la mécanique du Naze (le petit anneau qui serre) devient une plaque de nom. *Noms :* 1. **Nazes du Service** ; 2. **Nazes de Salle** ; 3. **Nazes en Livrée**.

### Les Convives Insatiables `[À CRÉER]`

Les invités du banquet perpétuel de Sauron, qui mangent depuis des siècles et ne sont jamais rassasiés : des gloutons au faciès creux, vêtements de fête en lambeaux. *Où :* Salle du Banquet, chapitre 7. *À peindre :* joues pendantes, bavoir de dentelle, couvert dans chaque main, le ventre énorme et la peau d'un blanc de cierge. Détail drôle : ils ont tous le même air satisfait et affamé à la fois. *Combat :* *Bouchée double* (vole un objet du sac et le mange), *Pas de dessert pour vous* (démoralise), *Faim de loup* (galvanise : le plus vorace passe devant) ; **on les neutralise en les nourrissant** : un objet de nourriture lancé les endort (sommeil, très efficace : Sam, *Plat de résistance*, fait même dormir toute une table) ; faiblesse torpeur, feu. *Bestiaire :* « Ils mangent pour oublier qu'ils n'ont plus faim. Ils ont oublié depuis longtemps. » *Double sens :* *convive* est un mot de bonne compagnie : c'est le nom de ceux qui partagent la table, et l'on n'en partage plus rien.

### Les Marcheurs Infatigables `[À CRÉER]`

Les pèlerins de l'escalier, qui montent sans fin vers la Montagne du Festin et n'ont jamais pu se reposer. *Où :* les Quatre Mille Marches, chapitre 7. *À peindre :* silhouettes grises, dos courbé, bâton à la main, qui grimpent en rond sur les paliers sans jamais avancer ; ils ont des chaussures usées à la corde. Détail drôle : chacun porte un petit panneau « Encore un peu ». *Combat :* ils ne veulent pas se battre : ils veulent qu'on **monte avec eux** ; *Encouragement* (galvanise les ennemis proches), *Encore un peu* (démoralise). On les apaise en **leur faisant s'asseoir** (voir la quête « Les Marcheurs infatigables »). Faiblesse torpeur ; état : sonné. *Bestiaire :* « Ils vont jusqu'au bout, c'est la seule chose qu'ils savent. Le bout n'a jamais l'air de se rapprocher. » *Noms :* 1. **Marcheurs Infatigables** ; 2. **Montagnards sans Pause** ; 3. **Pèlerins de la Marche**.

### Le Grand Œil et Sauron en pleine Vigueur `[EN JEU pour Sauron ; À CRÉER pour l'Œil]`

*Où :* le Grand Four, boss final, deux phases (voir `docs/HISTOIRE.md`). **Phase 1, le Grand Œil :** il n'a pas de corps ; il voit tout et ne peut rien. *À peindre :* un œil immense, de flamme et de fer, au centre d'un cercle de braise, une paupière qui bat ; il tourne lentement comme une broche (détail drôle : on le voit se tourner pour se faire dorer de l'autre côté). *Combat :* il **ne frappe pas** ; ses attaques sont des regards : *Regard insistant* (démoralise), *Mate-tout* (l'équipe voit ses points faibles révélés, ce qui augmente ses dégâts subis tout en augmentant les siens), *Rayon de veille* (dégâts de feu, ne dort jamais) ; immunisé contre le sommeil (le prologue le dit : sa faiblesse est la torpeur, pas le sommeil). **Phase 2, Sauron en pleine Vigueur :** l'armure du prologue, mais pleine, flamboyante : *Heures supplémentaires* (se redonne un tour), *Coup de masse*, *Regard insistant*, *Vigueur éternelle* (gagne un point d'élan par tour). Faiblesse : **torpeur** (le grand bâillement de Glandoulf, la berceuse de Sam), état : sommeil possible après trois assauts de torpeur ; il s'endort **à la fin du combat**, au lieu de mourir. *Bestiaire :* « Il travaille depuis trois mille ans. Il est le seul à ne pas s'en rendre compte. »

**Goulûm, deuxième acte** `[À RACCORDER]`. Au chapitre 7, Goulûm guide, trahit (il lâche l'équipe dans le col), puis se sacrifie dans les cuisines : voir le scénario. Son plus gros poisson, « le plus gros poisson du monde », est au menu du banquet.

---

## VIII. Table des boss par chapitre

| Chapitre | Boss et combats marquants | Mécanique propre |
|---|---|---|
| Prologue | Sauron en pleine Vigueur `[EN JEU]` | Torpeur comme faiblesse ; conseils à chaque tour |
| 1 | La Grande Baveuse, Le Vieux Solitaire, Monseigneur, le Naze `[EN JEU]` | Le Ramollissement divise les coups physiques |
| 2 | Le Vacherin, Chantecler, les deux Nazes de nuit `[EN JEU]` ; duels de bras de fer `[EN JEU]` | Le Serrage, le Cocorico |
| 3 | Le Gardien des Archives `[EN JEU]` | Règlement : triple exemplaire, consultation interdite |
| 4 `[À RACCORDER]` | Troll Affineur, Guetteur du lac, Goulûm, Le Balourd | Le Guetteur (quatre bras), Goulûm (duel d'énigmes), le Balourd (maladresse) |
| 5 | Uglouk et Grichnak, **Froton Anneauté**, Grimace Langue-de-Bois, **Sarumâle** | Serrage à faire descendre, langue de bois (coups courts), Réunion de service |
| 6 | Gothmoque, la Grondine, **le Dindon puis le Naze Suprême**, le Roi des Éveillés, le capitaine Saumure, un Mammou | « Nul homme du Gouda » (Aragrogne ne blesse pas, Merri frappe dans le dos), *Par décret : dormez* |
| 7 | La Bouche du Maître, l'Arachnée, la brigade des Nazes, le Grand Ologrill, **le Grand Œil puis Sauron** | Pourboire, Fatigue de l'Arachnée, Placement du maître de salle, Torpeur finale |

---

## IX. Questions pour l'auteur

Dix au plus, courtes ; la proposition par défaut est celle qui sera construite si l'auteur ne répond pas.

1. **Le nom des grands orques.** *Ouroukandouilles* (défaut), *Ouroukailles* (l'orthographe qu'il avait lui-même écrite) ou *Gros-Morfales* ? La piste « Ouroukouilles » est écartée : elle contient un mot cru, ce que la règle de ton interdit même en coupant le mot en deux.
2. **Les gobelins.** *Gobelardons* (défaut) ou *Gobe-Lards* ?
3. **Le niveau d'audace du titre.** Défaut : le titre se joue **dans les institutions** (l'Annulaire, l'Ordre du Garde-à-Vous, les alliances qui se portent à gauche, les anneaux de calamar du Guetteur, « au doigt et à l'œil »), jamais dans la bouche d'un personnage qui aurait conscience du double sens. Faut-il aller plus loin, ou moins loin ?
4. **Le Guetteur « Seigneur des Anneaux ».** Défaut : oui, c'est le surnom que lui donnent les nains, dit avec un sérieux complet. Trop appuyé ?
5. **Sauron s'endort-il vraiment ?** Défaut : oui, comme la bible, et sans mourir : c'est le dernier combat où l'on ne tue pas.
6. **Le sort de Bromure.** Défaut : il vit, alité, « enfin reposé », au chapitre 6, et s'excuse auprès de Froton (la bible disait « alité » ; on ne le fait pas mourir).
7. **Le sort de Goulûm.** Défaut : il trahit au col, puis se sacrifie dans les cuisines pour **son plus gros poisson**, qui est au menu ; la fin lui donne ce qu'il voulait.
8. **Les Éveillés.** Défaut : l'armée des morts est une armée de **dormeurs maudits par Isidur** (ils avaient promis de venir et sont restés au lit) ; Aragrogne les délivre en leur ordonnant de dormir. L'auteur préfère-t-il des parjures classiques (qui ont fui au lieu de dormir) ?
9. **Le Raidissement autour de Sauron.** Défaut : près du Mordgras, le Ramollissement s'inverse (les coups physiques portent **plus** fort, de 15 %), ce qui demande une petite valeur négative dans les cartes. Accepté ?
10. **Merri « Écuyer Tranchant ».** Défaut : au chapitre 5, il prête serment au roi et reçoit ce titre (celui qui tranche la viande à la table du roi), qui prépare son coup dans le dos au chapitre 6. Garder, ou préférer un titre plus simple (« page du roi », « porte-cartes ») ?
