# Brief : Insider Threat (app Flutter du Narrateur)

## Le projet
Jeu de déduction sociale inspiré des Loups-garous de Thiercelieux, transposé dans un réseau d'entreprise piraté (CORP-LAN). Il se joue de **5 à 14 joueurs**, avec **1 Narrateur humain**. L'app est le compagnon du Narrateur : elle affiche le texte à lire étape par étape, gère les choix de nuit, le suivi de partie, les timers et les Events. Tous les textes de l'app sont en anglais.

- **Dossier :** `/Users/elysabeth/English Game` (pas de dépôt git).
- **Plateformes :** iOS, Android, web. Flutter 3.47.5, Dart 3.13.

## Sources de référence
- **Règles :** `/Users/elysabeth/Downloads/Insider-Threat-Regles-FR-2.pdf` (version FR, 5 à 14 joueurs, quiz des Événements). Elle remplace le rulebook V2 et le `Insider-Threat-Rulebook.pdf` du dossier projet.
- **Events (mode Expert) :** `Insider-Threat-Evenement.pdf`, avec 10 Events. Il **remplace** la liste d'Events et les cartes Défense de la V2.
- **Prototype UI :** https://claude.ai/artifact/BmQjqDLJ2iXpw6dcXFAUc7 (canvas Design, board `Proto.dc.html`).
- **Moodboard :** `MOODBOARD.png` (vert acide, terminal CRT, glitch). Pas encore appliqué : l'app suit le look navy néon du prototype.
- **Exemple d'animation du tirage d'Event :** `/Users/elysabeth/Downloads/flutter_event_draw/`.

## Architecture
- `lib/game/` : moteur de règles en Dart pur, sans UI.
  - `game_controller.dart` : machine à états nuit, jour et fin. Gère les éliminations en chaîne (VPN, Dead Man's Switch, successeur du CISO), les conditions de victoire et les Events. Il expose un `GuideStep` que l'UI se contente d'afficher.
  - `night_script.dart` / `day_script.dart` : construction des étapes et textes « Say » (repris du rulebook).
  - `setup_controller.dart` : noms dans l'ordre de la table, rôles choisis à la main ou par scan, compositions recommandées (`compositions.dart`).
  - `card_code.dart` : format des QR des cartes, `INSIDERTHREAT:1:<role>:<nn>`.
- `lib/ui/` :
  - `home_screen` ;
  - `quiz_panel` : question, réponses, explication et saisie du nombre de bonnes réponses ;
  - `rules_screen` : bouton Rules de l'accueil, avec un sélecteur Game rules / Roles. Les règles reprennent `Insider-Threat-Rules-EN.pdf` (Events + quiz, sans les questions). Les rôles affichent le surnom, l'équivalent Loup-Garou (`RoleInfo.werewolf`) et le CISO. Si un rôle a un dessin officiel dans `roleArt` (Incident Responder et SOC Analyst pour l'instant, PNG sans fond dans `assets/characters/`), sa carte se retourne vers la gauche pour l'afficher ;
  - `setup_screen`, avec le bouton « Deal at random » pour tester sans cartes ;
  - `scan_screen` (mobile_scanner) ;
  - `guide_screen` (toutes les étapes de nuit et de jour) ;
  - `end_screen` ;
  - `widgets.dart`.
- `lib/theme/app_theme.dart` : couleurs et polices (Chakra Petch + JetBrains Mono via google_fonts).
- `qr-codes/` : 18 PNG et un PDF A4 à imprimer. Le jeu complet comprend 4 Red, 8 Defenders, 1 de chaque rôle spécial et 1 Purple. C'est plus que nécessaire pour 14 joueurs (3 Red et 5 Defenders au maximum), donc rien à réimprimer.

## Décisions prises (à garder)
- **Victoire du Red Team :** uniquement quand il ne reste que des Red, selon le rulebook. Le prototype, lui, arrêtait la partie dès que les Red égalaient les autres.
- **Night order :** construit à partir des rôles distribués. Un rôle éliminé est quand même appelé, avec un temps d'attente. Un rôle non distribué n'est **jamais** appelé, même si les règles le conseillent (choix de l'utilisatrice).
- **Compositions :** tableau des règles de 5 à 14 joueurs, sans interpolation. La Purple Team n'est autorisée qu'à 14 joueurs (bloqué dans le setup).
- **Chronos :** débat 3 min, élection du CISO 1 min.
- **C2 Server Down :** unanimité obligatoire, même à 4 attaquants.
- **Honeypot déclenché :** l'Incident Responder ne voit aucune victime et ne peut pas consommer son Backup Restore.
- **VPN Tunnel :** rappel au Narrateur pendant le vote (dans le « todo », jamais lu à voix haute).
- **Events :** tirés à partir du jour 2, juste après le rapport du matin (et l'élection du CISO s'il n'y en a pas). Tirage sans remise, puis le paquet est remélangé. Seulement en **mode Expert**, qui est désactivé par défaut dans le setup.
- **QR codes :** au **recto** des cartes, pour que tous les dos restent identiques.
- **Répliques inventées, à faire relire :** Dead Man's Switch, successeur du CISO, victoires Purple, VPN et Total Outage, et l'étape Dawn.

## État actuel
- **Pas de tests automatisés :** le dossier `test/` a été supprimé (MVP de 5 jours pour un concours d'école). On vérifie avec `flutter analyze` et en jouant sur téléphone. Build iOS simulateur OK.
- **Sur appareil :** l'utilisatrice a joué 2 parties entières, sans activer le mode Expert.
- **Scan QR :** non testé avec une vraie caméra.
- **Android :** SDK non installé sur le Mac, jamais buildé.

## Animation du tirage d'Event (faite)
Le déroulé est repris de `/Users/elysabeth/Downloads/flutter_event_draw/` : alerte « INCOMING EVENT », balayage, allumage CRT, glitch RGB, retournement 3D, puis révélation avec titre décodé et blocs en cascade. Les sons sont dans `assets/sfx/` et passent par `audioplayers`.

- **Code :** `lib/ui/event_draw/` (`event_draw_panel.dart`, `event_card_faces.dart`, `glitch.dart`, `sfx.dart`). Les textes imprimés des cartes sont dans `eventCardFaces` (`lib/game/events.dart`).
- **Fonctionnement :** le tirage est fait par le moteur, l'animation ne fait que révéler `todayEvent`. Elle se joue une seule fois par jour (`GameController.markEventRevealed`), avec un bouton « Replay the draw ».
- **Accessibilité :** le réglage « réduire les animations » est respecté.

## Quiz des Events (mode Expert)
- **Déroulé du jour :** tirage avec l'animation (`event`), puis la question avec 3 réponses mélangées et un chrono de 10 s (`quiz`). Ensuite, la bonne réponse et son explication, avec la saisie du nombre de bonnes réponses parmi les joueurs encore en jeu (`quizAnswer`). Enfin, le résultat (`eventResult`).
- **Règle :** « plus de la moitié » veut dire au moins `alive ~/ 2 + 1` joueurs.
  - Un Event **Blue** n'a lieu que si plus de la moitié a bon.
  - Un Event **Red** est bloqué si plus de la moitié a bon.
  - Un Event **Chaos** a toujours lieu.
- **Moteur :** `_drawEvent` ne fait plus que tirer la carte ; `_resolveQuiz` décide et applique les effets de jour (`_applyEffects`). `activeEvent` vaut `null` si l'Event est bloqué. La nuit reçoit `nightEvent = activeEvent`, donc un Event bloqué n'a aucun effet, ni le jour ni la nuit. Revenir en arrière puis changer le nombre de bonnes réponses fait recalculer le résultat.
- **Phishing Campaign (version simplifiée) :**
  - Le quiz affiche un e-mail tiré au hasard dans `phishEmails`, légitime ou phishing. Les joueurs répondent en levant 1 doigt pour « Legitimate » ou 2 pour « Phishing ».
  - Si la majorité a bon, c'est un malus pour la Red Team : elle n'est pas appelée la nuit suivante, donc pas d'attaque.
  - Si la majorité se trompe, c'est un bonus pour la Red Team : elle compromet 2 joueurs cette nuit-là. Le second ne peut pas être sauvé par le Backup Restore.
  - L'ancienne étape de nuit (3 destinataires, cliquer ou signaler) est supprimée.
- **Chronos courts à 1 minute :** réflexion du quiz, temps de parole DDoS et Dead Man's Switch. Le débat reste à 3 min et l'élection du CISO à 1 min.
- **Questions :** elles sont dans `eventQuizzes` (`lib/game/events.dart`), avec des explications rédigées pour l'appli.

## Réglages et confort
- **Réglages** (`lib/app_settings.dart`, enregistrés avec `shared_preferences`) : son on/off, volume général, « Narrator tips ». Le bouton réglages est en haut à droite de l'accueil, du setup et de la partie.
- **Son :** `Sfx` multiplie le volume de chaque son par `AppSettings.gain`. Un changement s'applique tout de suite aux ambiances en cours.
- **Narrator tips :** affiche la ligne « Do » (`step.todo`) sous le texte à lire, plus les rappels (`step.results`, par exemple « Show X the role card of Y »). Activé par défaut pour les débutants, et un Narrateur expérimenté peut tout couper.
- **Rules :** toute la barre « ← Rules » sert de retour. Un tap n'importe où sur une carte de rôle, ou sur sa flèche, la retourne avec une petite animation (340 ms, sans effet de zoom).
- **Setup :** le bouton « Reset players » vide les noms et les rôles. Taper ailleurs ou faire défiler la liste ferme le clavier.
- **Art :** la face personnage de la Red Team est la carte finie de l'équipe (`assets/characters/red_team_card.jpg`, déclarée dans `roleCardArt`). Le badge d'équipe remplace le surnom sur les cartes de rôle.

## Langue (anglais / français)
- **Réglage** : Paramètres → Langue (English / Français). Il est enregistré, et par défaut c'est la langue du téléphone.
- **Changement à chaud** : on peut changer avant, pendant ou après une partie. `LanguageScope` (dans `lib/i18n.dart`) reconstruit tout l'écran sans perdre la partie, et les textes du script sont recalculés à chaque affichage.
- **Pour ajouter un texte** : `tr('English', 'Français')`. Les données (rôles, Events, quiz, e-mails de phishing) sont des getters et pas des `const`, pour suivre la langue.
- **Restent en anglais dans les deux langues** : les noms des rôles et des Events (ce sont ceux des cartes imprimées), « Red/Blue/Purple Team », et les lignes « terminal » de l'écran de fin.
- **CISO** devient **RSSI** en français.

## Reste à faire ensuite
- **Mode Expert plus visible :** choix Base / Expert, et badge pendant la partie.
- **Ambiance sonore et sons des étapes :** actuellement « Audio coming soon ».
- **Polices intégrées** dans l'app : la release Android n'a pas la permission Internet, et le jeu doit pouvoir tourner hors ligne.
- **Écran toujours allumé** pendant la partie (wakelock).
- **Icône** de l'app.
- **Tests sur vrai téléphone** : scan QR et bouton retour Android.
- **Thème :** éventuellement repasser vers le moodboard.

## Consignes de l'utilisatrice
- Répondre en français.
- **Ne pas lancer le simulateur** : elle le fait elle-même. Analyser et builder, c'est OK. Pas de tests unitaires à écrire.
- Elle aime avancer par premier jet, puis vérifier ensemble.
