# Ma manette ne répond pas : mode d'emploi

Le jeu sait dire lui-même ce qu'il voit de la manette. Suivre ces étapes dans l'ordre, et s'arrêter
dès que ça marche.

1. **Brancher en USB d'abord.** Un câble USB (pas le Bluetooth) évite la plupart des soucis.
   Si la manette est sans fil, la débrancher de Windows (Paramètres, Bluetooth) puis la rejumeler.
2. **Fermer Steam**, complètement (clic droit sur l'icône près de l'horloge, Quitter). Steam
   « capte » les manettes et les présente autrement aux jeux : c'est la cause la plus fréquente.
   Relancer ensuite le jeu.
3. **Mettre la manette à jour** avec l'application « Accessoires Xbox » (Microsoft Store).
4. **Vérifier que Windows la voit** sur https://hardwaretester.com/gamepad : appuyer sur les
   boutons, les cases doivent s'allumer. Si rien ne s'allume là non plus, le problème est
   hors du jeu (câble, pile, jumelage).
5. **Cliquer une fois dans la fenêtre du jeu**, puis appuyer sur A.
6. **Ouvrir le diagnostic du jeu** :
   - sur l'écran-titre : la ligne « Manette » (au clavier : flèches et Entrée) ;
   - ou Paramètres, tout en bas, « Diagnostic de la manette ».

   L'écran dit en une phrase ce qui se passe :
   - « Aucune manette vue par le jeu » : le jeu ne la voit pas du tout (voir étapes 1 à 4) ;
   - « Manette vue mais aucun bouton reçu » : elle est vue mais muette (étape 5) ;
   - « Manette vue, boutons reçus : tout va bien » : elle marche.

   Appuyer sur des boutons : « Dernier bouton » et les cases de droite s'allument en direct.
7. **Nous rapporter** : la phrase affichée en haut de l'écran, et le texte du diagnostic.
   Choisir « Copier le diagnostic » puis le coller dans un message. Il est aussi écrit dans le
   fichier `manette.txt` du dossier de données du jeu (son chemin est affiché sur l'écran ; sous
   Windows : `%APPDATA%\Godot\app_userdata\Le Seigneur des Anneaux Péniens\manette.txt`).

Le jeu écrit aussi, à chaque lancement, une ligne `[manette]` dans sa console (version de Godot,
système, manettes vues). Quand une manette est branchée ou débranchée, un message le dit à l'écran.

Une manette que Godot ne connaît pas reçoit automatiquement une disposition « Xbox » standard.
La vibration (légère : coup reçu, coup critique, victoire) se règle dans Paramètres, « Manette ».
