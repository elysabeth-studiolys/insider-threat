# Insider Threat : plan de tournage du trailer

À lire avec [TRAILER_SCRIPT.md](TRAILER_SCRIPT.md). Ce plan reprend le script avec les corrections suivantes :
- vote au doigt sur « 3, 2, 1 » ;
- vraies répliques de l'app ;
- l'Incident Responder ne touche pas l'écran ;
- plus de surnom sur la carte Red Team ;
- l'intro et l'outro en motion design.

## Le montage final (2:00)

| Temps | Séquence | Source |
|---|---|---|
| 0:00 → 0:12 | 1. Cold open | Tourné (nuit) |
| 0:12 → 0:19 | 2. **Intro** (logo qui glitche, puis recul sur le hacker) | `Insider-Threat-Intro-Hacker.mp4`, rien à tourner |
| 0:19 → 0:32 | 3. Présentation | Tourné (jour) + captures d'écran |
| 0:32 → 0:50 | 4. La nuit | Tourné (nuit) |
| 0:50 → 1:08 | 5. La Blue Team | Tourné (nuit) |
| 1:08 → 1:30 | 6. Le jour | Tourné (jour) + capture du chrono |
| 1:30 → 1:46 | 7. Mode Expert | Captures d'écran + tourné (jour) |
| 1:46 → 1:52 | 8. Le traître se révèle | Tourné (jour, bascule nuit) |
| 1:52 → 2:00 | 9. **Outro** (on plonge dans l'écran, logo et tagline) | `Insider-Threat-Outro.mp4`, rien à tourner |

L'intro et l'outro ajoutent environ 3 s par rapport au script V1. On les reprend sur la séquence 5 : le Network Engineer devient optionnel.

---

## Le plan, plan par plan

Abréviations de cadre : **PL** plan large, **PR** plan rapproché, **GP** gros plan, **INS** insert (objet ou écran).

### 1. Cold open (0:00 → 0:12) · lumière NUIT

| # | Cadre | Action | Mouvement | Durée |
|---|---|---|---|---|
| 1.1 | PL | La table dans le noir, tout le monde a les yeux fermés, seul le téléphone au centre éclaire. | Travelling latéral très lent sur les visages | 5 s |
| 1.2 | INS | Une main retourne à moitié une carte : on lit « RED TEAM ». On ne voit pas à qui est la main. | Fixe | 2 s |
| 1.3 | GP | Le **traître** (sweat à capuche sombre, capuche baissée) ouvre les yeux face caméra sur « next to you ». Il ne sourit pas. | Léger zoom avant | 3 s |

VO : *Every company has a network. Every network has a weakness… And sometimes… the weakness is sitting right next to you.*

### 3. Présentation (0:19 → 0:32) · lumière JOUR

| # | Cadre | Action | Mouvement | Durée |
|---|---|---|---|---|
| 3.1 | PL | Les amis arrivent, rient et s'installent. Le traître s'assoit, capuche baissée. | Fixe ou épaule | 3 s |
| 3.2 | GP | Mains qui distribuent les cartes face cachée. | Plongée | 2 s |
| 3.3 | GP | Le téléphone passe au-dessus d'une carte pour scanner le QR. | Fixe | 2 s |
| 3.4 | INS écran | Capture : l'écran de scan qui reconnaît la carte. | — | 2 s |
| 3.5 | INS écran | Capture : le Narrateur tape les noms dans le setup. | — | 2 s |

Texte à l'écran : « 5–14 PLAYERS · 1 NARRATOR · 1 APP ».
VO : *Welcome to CORP-LAN. Five to fourteen players. One Narrator. One app that runs the whole game. And somewhere around this table… a hacker.*

### 4. La nuit (0:32 → 0:50) · lumière NUIT

| # | Cadre | Action | Mouvement | Durée |
|---|---|---|---|---|
| 4.1 | PL | Le Narrateur tient le téléphone, tout le monde ferme les yeux. | Fixe | 4 s |
| 4.2 | PR | Le visage du Narrateur, éclairé par le téléphone, lit sa réplique. | Fixe | 4 s |
| 4.3 | GP yeux | **Deux paires d'yeux** s'ouvrent et se regardent. Cadrer très serré, sur les yeux seulement : **on ne doit pas reconnaître le traître.** | Fixe | 3 s |
| 4.4 | GP | Une main pointe quelqu'un, en silence. | Fixe | 2 s |
| 4.5 | PR | Max dort, sans se douter de rien. | Léger zoom avant | 3 s |

IN (Narrateur), le vrai texte de l'app :
- *Night falls on CORP-LAN. All employees, log off and close your eyes.*
- *Red Team, wake up. Look at each other. Silently choose one machine to compromise.*

VO : *At night, the Red Team wakes up. Silent. Coordinated. Choosing their next target.*

### 5. La Blue Team (0:50 → 1:08) · lumière NUIT

Un rôle par plan, sans dialogue, 2 à 3 s chacun.

| # | Cadre | Action | Durée |
|---|---|---|---|
| 5.1 | GP | Le **Threat Hunter** pointe un joueur. | 2 s |
| 5.2 | INS | Le Narrateur lui montre discrètement une carte. | 2 s |
| 5.3 | GP | Le regard du Threat Hunter change. | 2 s |
| 5.4 | GP | La **SOC Analyst** entrouvre les yeux entre ses doigts pendant le tour des Red. | 3 s |
| 5.5 | GP main | L'**Incident Responder** : son pouce hésite entre levé (Backup Restore) et baissé. Il ne touche pas l'écran, l'app sert uniquement au Narrateur. | 3 s |
| 5.6 | PR | *(optionnel, à couper si c'est trop long)* Le **Network Engineer** : le Narrateur touche l'épaule de deux joueurs. | 2 s |

VO : *But the Blue Team fights back. A Threat Hunter who sees through any disguise. A SOC Analyst who never really sleeps. An Incident Responder… with one backup, and one kill switch.*

### 6. Le jour (1:08 → 1:30) · lumière JOUR

| # | Cadre | Action | Mouvement | Durée |
|---|---|---|---|---|
| 6.1 | PL | La lumière revient d'un coup, tout le monde ouvre les yeux. | Fixe | 2 s |
| 6.2 | PR | Le Narrateur lit le rapport du matin. | Fixe | 3 s |
| 6.3 | GP | Max retourne sa carte, dépité. | Fixe | 2 s |
| 6.4 | INS écran | Capture : le chrono de débat 3:00 qui défile. | — | 2 s |
| 6.5 | PR × 3 | Le débat : un doigt accusateur, quelqu'un qui se défend, un regard en coin. | Épaule | 5 s |
| 6.6 | PL plongée | **Le vote** : sur « 3, 2, 1 », **tout le monde pointe un joueur en même temps**. | Fixe, en hauteur | 3 s |
| 6.7 | GP | Le joueur éliminé retourne sa carte : **Defender**. | Fixe | 2 s |
| 6.8 | PL | Un silence gêné autour de la table. | Travelling arrière lent | 3 s |

IN (Narrateur) : *Good morning, CORP-LAN. Overnight, one machine went offline: Max has been compromised.* Couper la suite (« Max, show us your card »).
VO : *By day, everyone is a suspect. Debate. Accuse. Vote. Get it wrong… and you just fired your best defender.*

### 7. Mode Expert (1:30 → 1:46) · lumière JOUR

| # | Cadre | Action | Durée |
|---|---|---|---|
| 7.1 | INS écran | Capture : l'animation de tirage d'Event (alerte, allumage CRT, carte **Phishing Campaign**). | 4 s |
| 7.2 | INS écran | Capture : l'e-mail du quiz Phishing. | 3 s |
| 7.3 | PR × 2 | Des joueurs réfléchissent, sourcils froncés. | 3 s |
| 7.4 | PL + GP mains | Sur « 3, 2, 1 », chacun montre **1 doigt (legitimate) ou 2 doigts (phishing)**. | 3 s |

Texte à l'écran : « EXPERT MODE ».
VO : *Play Expert mode, and real cyberattacks hit the office. Phishing. DDoS. Zero-Day. Answer right, together… or hand the hackers the keys.*

### 8. Le traître se révèle (1:46 → 1:52) · lumière JOUR, puis bascule NUIT

| # | Cadre | Action | Mouvement | Durée |
|---|---|---|---|---|
| 8.1 | PL plongée | Le dernier vote, **au ralenti** : tout le monde pointe… mais pas le traître. | Fixe, tourné en 60 ou 120 i/s | 2 s |
| 8.2 | INS | Il pose sa carte face visible : **RED TEAM**. | Fixe | 1,5 s |
| 8.3 | GP | Il remonte sa capuche et regarde la caméra. La lumière bascule en ambiance nuit verte. | Zoom avant lent | 2,5 s |

Couper la musique net au début de 8.1.
VO : *Trust is a vulnerability.*

Enchaîner directement sur l'**outro** : le plan large du hacker encapuchonné, puis on plonge dans l'écran. La VO dit *Insider Threat.*, et le texte « THE THREAT IS ALREADY INSIDE » reste affiché sous le logo.

---

## Captures d'écran à enregistrer

Enregistrer avec l'enregistreur d'écran du téléphone (mode avion, luminosité au maximum, notifications coupées). Lancer une vraie partie test pour les obtenir.

- [ ] Scan d'une carte QR (3.4)
- [ ] Setup avec les noms (3.5)
- [ ] Chrono de débat (6.4)
- [ ] Tirage de l'Event Phishing Campaign (7.1)
- [ ] E-mail du quiz Phishing (7.2)

## Ordre de tournage conseillé

On tourne par ambiance de lumière, pas dans l'ordre du film.

1. **Avant le jour J :** enregistrer la voix off (le montage se cale dessus) et les captures d'écran.
2. **Bloc JOUR :** 3, 6, 7, puis 8.1 et 8.2.
3. **Bascule de lumière :** 8.3.
4. **Bloc NUIT :** 1, 4, 5.

Prévoir 3 à 4 h de tournage avec la mise en place.

## Casting et costumes

| Rôle à l'écran | Indispensable | Note |
|---|---|---|
| Narrateur | Oui | Tient le téléphone, lit les répliques. |
| Le traître | Oui | **Sweat à capuche sombre** : c'est la silhouette de l'intro et de l'outro. |
| Max | Oui | Vérifier que ce n'est pas le vrai prénom d'un des acteurs. |
| Defender éliminé par erreur | Oui | — |
| Threat Hunter, SOC Analyst, Incident Responder | Figurants | Peuvent jouer d'autres joueurs dans les plans larges. |
| 1 à 2 joueurs en plus | Figurants | Pour remplir la table (7 à 8 joueurs au total). |

Tenues neutres et sombres, sans logo, pour que le traître ne sorte pas trop du lot.

## Matériel

- Une caméra ou un téléphone en 4K, avec du **60 ou 120 i/s pour le ralenti** (8.1).
- Un trépied, plus un appui en hauteur pour les plongées (6.6, 8.1).
- Une LED verte ou bleue pour l'ambiance nuit, en lumière chaude pour le jour.
- Les vraies cartes imprimées, dont plusieurs cartes Defender et Red Team.
- Le téléphone du Narrateur avec l'app, en mode « Ne pas déranger ».

## Raccords

- Prendre une **photo de la table** (qui est assis où, avec quelle carte) avant le premier plan, et la respecter dans tous les plans.
- Le traître garde la même place, et sa capuche reste baissée jusqu'au plan 8.3.
- Dans le bloc nuit, ne jamais cadrer le traître de façon reconnaissable quand la Red Team se réveille (4.3).
