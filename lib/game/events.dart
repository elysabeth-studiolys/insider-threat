/// Expert mode Event cards (Insider-Threat-Evenement.pdf, 10 events).
library;

import '../i18n.dart';

enum EventCard {
  securityAudit,
  c2ServerDown,
  honeypot,
  powerOutage,
  zeroDay,
  maintenanceWindow,
  remoteWorkDay,
  phishing,
  blackFridayRush,
  ddos,
}

enum EventSide { blue, red, chaos }

extension EventSideX on EventSide {
  String get label => switch (this) {
        EventSide.blue => tr('Helps Blue Team', 'Aide la Blue Team'),
        EventSide.red => tr('Helps Red Team', 'Aide la Red Team'),
        EventSide.chaos => 'Chaos',
      };
}

class EventInfo {
  const EventInfo({
    required this.number,
    required this.title,
    required this.side,
    required this.when,
    required this.description,
    required this.howTo,
  });

  final int number;
  final String title;
  final EventSide side;
  final String when;
  final String description;
  final String howTo;
}

/// Event titles stay in English in both languages: they match the printed cards.
/// Built on each access so the texts follow the current language.
Map<EventCard, EventInfo> get eventInfos => {
  EventCard.securityAudit: EventInfo(
    number: 1,
    title: 'Security Audit',
    side: EventSide.blue,
    when: tr('Tonight', 'Cette nuit'),
    description: tr('An external security audit gives the Blue Team more resources to investigate.',
        "Un audit de sécurité externe donne à la Blue Team plus de moyens pour enquêter."),
    howTo: tr(
        'Tonight the Threat Hunter may inspect two machines. The app adapts the script: show both role cards, one after the other.',
        "Cette nuit, le Threat Hunter peut inspecter deux machines. L'appli adapte le script : montrez les deux cartes, l'une après l'autre."),
  ),
  EventCard.c2ServerDown: EventInfo(
    number: 2,
    title: 'C2 Server Down',
    side: EventSide.blue,
    when: tr('Tonight', 'Cette nuit'),
    description: tr(
        "The attackers' Command & Control server is down. They can no longer coordinate and must act alone.",
        "Le serveur de commande et contrôle (C2) des attaquants est tombé. Ils ne peuvent plus se coordonner et doivent agir seuls."),
    howTo: tr(
        'Tonight the Red Team (Purple included) is called one attacker at a time. If they all point at the same machine it is compromised, otherwise the attack fails.',
        "Cette nuit, la Red Team (Purple comprise) est appelée un attaquant à la fois. S'ils désignent tous la même machine, elle est compromise ; sinon, l'attaque échoue."),
  ),
  EventCard.honeypot: EventInfo(
    number: 3,
    title: 'Honeypot',
    side: EventSide.blue,
    when: tr('Tonight', 'Cette nuit'),
    description: tr(
        'The Blue Team has set up a decoy on the network: a machine that looks vulnerable but is a trap.',
        "La Blue Team a placé un leurre sur le réseau : une machine qui a l'air vulnérable mais qui est un piège."),
    howTo: tr(
        'At nightfall the app secretly picks one online machine outside the Red Team. If the Red Team targets it, the attack fails. Tell nobody who the decoy is.',
        "À la tombée de la nuit, l'appli choisit en secret une machine en ligne hors de la Red Team. Si la Red Team la vise, l'attaque échoue. Ne dites à personne qui est le leurre."),
  ),
  EventCard.powerOutage: EventInfo(
    number: 4,
    title: 'Power Outage',
    side: EventSide.red,
    when: tr('Tonight', 'Cette nuit'),
    description: tr('A power cut takes every defence tool offline.',
        'Une coupure de courant met tous les outils de défense hors ligne.'),
    howTo: tr(
        'Tonight only the Red Team is called. No Threat Hunter, no Incident Responder, no Purple solo action, and the SOC Analyst cannot peek.',
        "Cette nuit, seule la Red Team est appelée. Pas de Threat Hunter, pas d'Incident Responder, pas d'action seule de la Purple Team, et la SOC Analyst ne peut pas espionner."),
  ),
  EventCard.zeroDay: EventInfo(
    number: 5,
    title: 'Zero-Day',
    side: EventSide.red,
    when: tr('Tonight', 'Cette nuit'),
    description: tr(
        'The Red Team exploits an unknown flaw that is also present in the backups: restoring the machine is useless.',
        'La Red Team exploite une faille inconnue, présente aussi dans les sauvegardes : restaurer la machine ne sert à rien.'),
    howTo: tr(
        'Tonight Backup Restore is unavailable. It is not used up: the Incident Responder keeps it for later. Kill Process still works.',
        "Cette nuit, Backup Restore est indisponible. Il n'est pas consommé : l'Incident Responder le garde pour plus tard. Kill Process fonctionne toujours."),
  ),
  EventCard.maintenanceWindow: EventInfo(
    number: 6,
    title: 'Maintenance Window',
    side: EventSide.red,
    when: tr('Today', "Aujourd'hui"),
    description: tr('A planned maintenance window freezes every change on the network today.',
        "Une maintenance planifiée gèle tous les changements sur le réseau aujourd'hui."),
    howTo: tr(
        'The debate happens as usual. At the end, announce that no quarantine happens today. There is no vote.',
        "Le débat a lieu normalement. À la fin, annoncez qu'il n'y a pas de quarantaine aujourd'hui. Il n'y a pas de vote."),
  ),
  EventCard.remoteWorkDay: EventInfo(
    number: 7,
    title: 'Remote Work Day',
    side: EventSide.red,
    when: tr('Today', "Aujourd'hui"),
    description: tr(
        'Everyone works from home. Nobody meets at the coffee machine, so there is no discussion.',
        'Tout le monde est en télétravail. Personne ne se croise à la machine à café, donc pas de discussion.'),
    howTo: tr(
        'No debate. Start the countdown right away: everyone points at a player in silence. Usual voting rules apply.',
        "Pas de débat. Lancez le compte à rebours tout de suite : chacun désigne un joueur en silence. Les règles de vote habituelles s'appliquent."),
  ),
  EventCard.phishing: EventInfo(
    number: 8,
    title: 'Phishing Campaign',
    side: EventSide.chaos,
    when: tr('Today, effect tonight', "Aujourd'hui, effet cette nuit"),
    description: tr('A suspicious email lands in every inbox. Is it legitimate, or is it phishing?',
        'Un e-mail suspect arrive dans toutes les boîtes. Est-il légitime, ou est-ce du phishing ?'),
    howTo: tr(
        'The quiz shows an email. Everyone decides together: legitimate or phishing? Majority right: malus for the Red Team, their attack fails tonight. Majority wrong: bonus for the Red Team, they compromise 2 machines tonight.',
        "Le quiz affiche un e-mail. Chacun décide : légitime ou phishing ? Majorité de bonnes réponses : malus pour la Red Team, son attaque échoue cette nuit. Majorité de mauvaises réponses : bonus pour la Red Team, elle compromet 2 machines cette nuit."),
  ),
  EventCard.blackFridayRush: EventInfo(
    number: 9,
    title: 'Black Friday Rush',
    side: EventSide.chaos,
    when: tr('Today', "Aujourd'hui"),
    description: tr("It's Black Friday: everyone is swamped and nobody has time to talk.",
        "C'est le Black Friday : tout le monde est débordé et personne n'a le temps de parler."),
    howTo: tr('The debate lasts only 1 minute. Then the vote happens as usual.',
        'Le débat ne dure que 1 minute. Ensuite, le vote se déroule normalement.'),
  ),
  EventCard.ddos: EventInfo(
    number: 10,
    title: 'DDoS',
    side: EventSide.chaos,
    when: tr('Today', "Aujourd'hui"),
    description: tr(
        'The network is flooded by a denial-of-service attack: only one message gets through at a time.',
        'Le réseau est saturé par une attaque par déni de service : un seul message passe à la fois.'),
    howTo: tr(
        'No free debate. One round, one player at a time, 1 minute each, starting with the player to the left of the CISO. Nobody can interrupt.',
        'Pas de débat libre. Un seul tour, un joueur à la fois, 1 minute chacun, en commençant par le joueur à gauche du RSSI. Personne ne peut interrompre.'),
  ),
};

extension EventCardX on EventCard {
  EventInfo get info => eventInfos[this]!;
}

/// Text printed on the physical Event card (from the card design).
/// Words wrapped in `**double stars**` are highlighted.
class EventCardFace {
  const EventCardFace({required this.flavor, required this.effect, required this.when});

  final String flavor;
  final String effect;

  /// Short timing label printed on the card: TONIGHT or TODAY.
  final String when;
}

Map<EventCard, EventCardFace> get eventCardFaces => {
  EventCard.securityAudit: EventCardFace(
    when: tr('TONIGHT', 'CETTE NUIT'),
    flavor: tr('An external audit boosts the investigation.', "Un audit externe renforce l'enquête."),
    effect: tr('The Threat Hunter inspects **2 machines** instead of 1.',
        'Le Threat Hunter inspecte **2 machines** au lieu de 1.'),
  ),
  EventCard.c2ServerDown: EventCardFace(
    when: tr('TONIGHT', 'CETTE NUIT'),
    flavor: tr("The attackers' Command & Control server is down.", 'Le serveur C2 des attaquants est tombé.'),
    effect: tr(
        'Attackers are woken **one at a time** and point alone. The target goes down only if they **all** chose the same machine.',
        'Les attaquants sont réveillés **un par un** et désignent seuls. La cible tombe seulement si **tous** ont choisi la même machine.'),
  ),
  EventCard.honeypot: EventCardFace(
    when: tr('TONIGHT', 'CETTE NUIT'),
    flavor: tr('A decoy machine waits on the network.', 'Une machine leurre attend sur le réseau.'),
    effect: tr(
        'The Narrator secretly picks a decoy (not Red Team). If the Red Team targets it, the attack **fails**: "Honeypot triggered."',
        "Le Narrateur choisit en secret un leurre (hors Red Team). Si la Red Team le vise, l'attaque **échoue** : « Honeypot déclenché »."),
  ),
  EventCard.powerOutage: EventCardFace(
    when: tr('TONIGHT', 'CETTE NUIT'),
    flavor: tr('A power cut takes every defence tool offline.', 'Une coupure de courant met toutes les défenses hors ligne.'),
    effect: tr('Only the Red Team acts. **All special powers are offline**, and the SOC Analyst cannot peek.',
        'Seule la Red Team agit. **Tous les pouvoirs sont hors ligne**, et la SOC Analyst ne peut pas espionner.'),
  ),
  EventCard.zeroDay: EventCardFace(
    when: tr('TONIGHT', 'CETTE NUIT'),
    flavor: tr('An unknown flaw, even in the backups.', 'Une faille inconnue, jusque dans les sauvegardes.'),
    effect: tr('**Backup Restore cannot be used** (it is not used up). Kill Process still works.',
        "**Backup Restore est inutilisable** (il n'est pas consommé). Kill Process fonctionne toujours."),
  ),
  EventCard.maintenanceWindow: EventCardFace(
    when: tr('TODAY', "AUJOURD'HUI"),
    flavor: tr('Planned maintenance freezes the network.', 'Une maintenance planifiée gèle le réseau.'),
    effect: tr('Debate as usual, then **no vote and no quarantine** today.',
        "Débat normal, puis **ni vote ni quarantaine** aujourd'hui."),
  ),
  EventCard.remoteWorkDay: EventCardFace(
    when: tr('TODAY', "AUJOURD'HUI"),
    flavor: tr('No coffee machine, no discussion.', 'Pas de machine à café, pas de discussion.'),
    effect: tr('**No debate.** Everyone votes immediately, in silence.',
        '**Pas de débat.** Tout le monde vote tout de suite, en silence.'),
  ),
  EventCard.phishing: EventCardFace(
    when: tr('TODAY', "AUJOURD'HUI"),
    flavor: tr('Legit or phishing?', 'Légitime ou phishing ?'),
    effect: tr(
        "Everyone checks the same email. **Majority right**: the Red Team's attack **fails** tonight. **Majority wrong**: the Red Team compromises **2 machines** tonight.",
        "Tout le monde examine le même e-mail. **Majorité juste** : l'attaque de la Red Team **échoue** cette nuit. **Majorité fausse** : la Red Team compromet **2 machines** cette nuit."),
  ),
  EventCard.blackFridayRush: EventCardFace(
    when: tr('TODAY', "AUJOURD'HUI"),
    flavor: tr('Everyone is swamped.', 'Tout le monde est débordé.'),
    effect: tr('The debate lasts only **1 minute**.', 'Le débat ne dure que **1 minute**.'),
  ),
  EventCard.ddos: EventCardFace(
    when: tr('TODAY', "AUJOURD'HUI"),
    flavor: tr('One message at a time.', 'Un message à la fois.'),
    effect: tr('No free debate. Each player speaks **once, in turn**, 1 minute max.',
        'Pas de débat libre. Chaque joueur parle **une fois, à tour de rôle**, 1 minute max.'),
  ),
};

extension EventCardFaceX on EventCard {
  EventCardFace get face => eventCardFaces[this]!;
}

/// Expert mode quiz: one question per Event, in the current language. The players'
/// answers decide whether the Event happens (see [EventSide] rules in the
/// rulebook): Blue Events need more than half right, Red Events are blocked
/// when more than half are right, Chaos Events always happen.
class EventQuiz {
  const EventQuiz({
    required this.question,
    required this.answers,
    required this.correct,
    required this.explanation,
  });

  final String question;

  /// The three answers, in a fixed order. The game shuffles them per draw.
  final List<String> answers;

  /// Index of the right answer in [answers].
  final int correct;

  /// Short explanation shown with the right answer.
  final String explanation;
}

/// Built on each access so the texts follow the current language.
Map<EventCard, EventQuiz> get eventQuizzes => {
  EventCard.securityAudit: EventQuiz(
    question: tr('What is the main goal of a security audit?', "Quel est le but principal d'un audit de sécurité ?"),
    answers: [
      tr('Find weaknesses before attackers do', 'Trouver les failles avant les attaquants'),
      tr('Punish employees who made mistakes', 'Sanctionner les employés qui ont fait des erreurs'),
      tr('Replace the antivirus', "Remplacer l'antivirus"),
    ],
    correct: 0,
    explanation: tr(
        'An audit checks systems and habits to find security gaps, so they can be fixed before anyone exploits them.',
        "Un audit vérifie les systèmes et les habitudes pour trouver les failles, afin de les corriger avant que quelqu'un ne les exploite."),
  ),
  EventCard.c2ServerDown: EventQuiz(
    question: tr('What is a C2 (Command & Control) server?', "Qu'est-ce qu'un serveur C2 (Command & Control) ?"),
    answers: [
      tr("The company's main backup server", "Le serveur de sauvegarde principal de l'entreprise"),
      tr('A server attackers use to control infected machines', 'Un serveur qui permet aux attaquants de piloter les machines infectées'),
      tr('A server that filters spam', 'Un serveur qui filtre le spam'),
    ],
    correct: 1,
    explanation: tr(
        'Infected machines call home to the C2 server to receive orders. Without it, the attackers can no longer coordinate.',
        "Les machines infectées contactent le serveur C2 pour recevoir leurs ordres. Sans lui, les attaquants ne peuvent plus se coordonner."),
  ),
  EventCard.honeypot: EventQuiz(
    question: tr('What is a honeypot?', "Qu'est-ce qu'un honeypot ?"),
    answers: [
      tr('A vault that stores passwords', 'Un coffre-fort qui stocke les mots de passe'),
      tr('A firewall rule that blocks all traffic', 'Une règle de pare-feu qui bloque tout le trafic'),
      tr('A decoy system that attracts and detects attackers', 'Un système leurre qui attire et détecte les attaquants'),
    ],
    correct: 2,
    explanation: tr(
        'A honeypot looks like an easy target. Attackers who touch it reveal themselves while the defenders watch.',
        "Un honeypot ressemble à une cible facile. Les attaquants qui y touchent se dévoilent sous les yeux des défenseurs."),
  ),
  EventCard.powerOutage: EventQuiz(
    question: tr('What keeps critical servers running during a power cut?',
        'Qu’est-ce qui maintient les serveurs critiques en marche pendant une coupure de courant ?'),
    answers: [
      tr('A UPS (uninterruptible power supply)', 'Un onduleur (alimentation sans interruption)'),
      tr('A VPN', 'Un VPN'),
      tr('A proxy server', 'Un serveur proxy'),
    ],
    correct: 0,
    explanation: tr(
        'A UPS gives battery power long enough to switch to a generator or to shut the servers down safely.',
        "Un onduleur fournit assez de batterie pour basculer sur un groupe électrogène ou éteindre les serveurs proprement."),
  ),
  EventCard.zeroDay: EventQuiz(
    question: tr('What is a zero-day vulnerability?', "Qu'est-ce qu'une faille zero-day ?"),
    answers: [
      tr('A flaw fixed on the day it is found', 'Une faille corrigée le jour même de sa découverte'),
      tr('A flaw unknown to the vendor, with no patch yet', "Une faille inconnue de l'éditeur, sans correctif pour l'instant"),
      tr('A virus that activates at midnight', 'Un virus qui se déclenche à minuit'),
    ],
    correct: 1,
    explanation: tr(
        'Defenders have had "zero days" to fix it: no patch exists yet, which makes it very dangerous.',
        "Les défenseurs ont eu « zéro jour » pour la corriger : aucun correctif n'existe encore, ce qui la rend très dangereuse."),
  ),
  EventCard.maintenanceWindow: EventQuiz(
    question: tr('Why do companies plan maintenance windows?', 'Pourquoi les entreprises planifient-elles des fenêtres de maintenance ?'),
    answers: [
      tr('To give employees a day off', 'Pour donner un jour de congé aux employés'),
      tr('To delete old accounts automatically', 'Pour supprimer automatiquement les anciens comptes'),
      tr('To install updates with minimal impact on users', 'Pour installer les mises à jour en gênant le moins possible les utilisateurs'),
    ],
    correct: 2,
    explanation: tr(
        'Patching on a planned schedule keeps systems secure without stopping people in the middle of their work.',
        'Installer les correctifs à heure prévue garde les systèmes sécurisés sans interrompre les gens en plein travail.'),
  ),
  EventCard.remoteWorkDay: EventQuiz(
    question: tr('What is the safest way to connect to the company network from home?',
        "Quelle est la façon la plus sûre de se connecter au réseau de l'entreprise depuis chez soi ?"),
    answers: [
      tr('Through the company VPN', "Par le VPN de l'entreprise"),
      tr('Through free public Wi-Fi', 'Par un Wi-Fi public gratuit'),
      tr("With a colleague's account", "Avec le compte d'un collègue"),
    ],
    correct: 0,
    explanation: tr(
        'A VPN encrypts the connection between your computer and the company network. Never share accounts.',
        "Un VPN chiffre la connexion entre ton ordinateur et le réseau de l'entreprise. Ne partage jamais de compte."),
  ),
  EventCard.phishing: EventQuiz(
    question: tr('You get an urgent email asking you to reset your password with a link. What do you do?',
        'Tu reçois un e-mail urgent qui te demande de réinitialiser ton mot de passe via un lien. Que fais-tu ?'),
    answers: [
      tr('Click quickly before it expires', "Cliquer vite avant que ça expire"),
      tr('Report it to the IT / security team', "Le signaler à l'équipe informatique / sécurité"),
      tr('Forward it to colleagues', "Le transférer aux collègues"),
    ],
    correct: 1,
    explanation: tr(
        'Urgency is a classic phishing trick. One report lets the security team block the email for everyone.',
        "L'urgence est une ruse classique du phishing. Un seul signalement permet à l'équipe sécurité de bloquer l'e-mail pour tout le monde."),
  ),
  EventCard.blackFridayRush: EventQuiz(
    question: tr('What is a common online scam during Black Friday?', 'Quelle arnaque en ligne est courante pendant le Black Friday ?'),
    answers: [
      tr('Banks closing accounts', 'Des banques qui ferment des comptes'),
      tr('Free antivirus updates', "Des mises à jour d'antivirus gratuites"),
      tr('Fake shopping sites with too-good-to-be-true deals', 'Des faux sites marchands avec des promos trop belles pour être vraies'),
    ],
    correct: 2,
    explanation: tr(
        'Scammers copy real shops to steal payment details. Always check the website address before paying.',
        "Les escrocs copient de vraies boutiques pour voler les données de paiement. Vérifie toujours l'adresse du site avant de payer."),
  ),
  EventCard.ddos: EventQuiz(
    question: tr('What does a DDoS attack do?', 'Que fait une attaque DDoS ?'),
    answers: [
      tr('Floods a service with traffic so it becomes unavailable', "Elle inonde un service de trafic jusqu'à le rendre indisponible"),
      tr('Steals passwords from a database', "Elle vole les mots de passe d'une base de données"),
      tr('Encrypts files and asks for a ransom', 'Elle chiffre les fichiers et demande une rançon'),
    ],
    correct: 0,
    explanation: tr(
        'Thousands of machines send requests at the same time until the service can no longer answer. Encrypting files for a ransom is ransomware.',
        "Des milliers de machines envoient des requêtes en même temps jusqu'à ce que le service ne puisse plus répondre. Chiffrer des fichiers contre une rançon, c'est un ransomware."),
  ),
};

extension EventQuizX on EventCard {
  EventQuiz get quiz => eventQuizzes[this]!;
}


/// Emails used by the Phishing Campaign quiz. One is picked at random each
/// time the Event is drawn; players decide whether it is legitimate.
class PhishEmail {
  const PhishEmail({
    required this.from,
    required this.subject,
    required this.body,
    required this.isPhishing,
    required this.explanation,
  });

  final String from;
  final String subject;
  final String body;
  final bool isPhishing;
  final String explanation;
}

/// Built on each access so the texts follow the current language. The order
/// never changes: the game stores the index of today's email.
List<PhishEmail> get phishEmails => [
  PhishEmail(
    from: 'it-support@corp-lan-security.co',
    subject: tr('URGENT: your password expires in 1 hour', 'URGENT : votre mot de passe expire dans 1 heure'),
    body: tr('Your account will be locked today. Click here and enter your password to keep access.',
        "Votre compte sera bloqué aujourd'hui. Cliquez ici et saisissez votre mot de passe pour garder l'accès."),
    isPhishing: true,
    explanation: tr(
        'Phishing: the sender domain is not the company one, the tone is urgent, and IT never asks for your password.',
        "Phishing : le domaine de l'expéditeur n'est pas celui de l'entreprise, le ton est urgent, et le service informatique ne demande jamais ton mot de passe."),
  ),
  PhishEmail(
    from: 'ceo.office@gmail.com',
    subject: tr('Quick favour, confidential', 'Petit service, confidentiel'),
    body: tr('I am in a meeting. Buy 5 gift cards of 100 euros and send me the codes. Keep this between us.',
        "Je suis en réunion. Achetez 5 cartes cadeaux de 100 euros et envoyez-moi les codes. Que ça reste entre nous."),
    isPhishing: true,
    explanation: tr(
        'Phishing (CEO fraud): a personal address, secrecy, pressure and gift cards. Always check by phone.',
        "Phishing (fraude au président) : une adresse personnelle, du secret, de la pression et des cartes cadeaux. Vérifie toujours par téléphone."),
  ),
  PhishEmail(
    from: 'delivery@parcel-track.info',
    subject: tr('Your parcel is on hold', 'Votre colis est en attente'),
    body: tr('Delivery failed. Pay 1.99 euros of fees within 24 hours on our website or your parcel will be returned.',
        "Échec de la livraison. Payez 1,99 euro de frais sous 24 heures sur notre site, sinon votre colis sera renvoyé."),
    isPhishing: true,
    explanation: tr(
        'Phishing: an unknown domain, a small payment to collect your card details, and a deadline.',
        "Phishing : un domaine inconnu, un petit paiement pour récupérer ta carte bancaire, et un délai."),
  ),
  PhishEmail(
    from: 'it-support@corp-lan.com',
    subject: tr('Planned maintenance on Saturday', 'Maintenance prévue samedi'),
    body: tr('The mail server will be updated on Saturday from 8 to 10 am. No action is needed on your side.',
        "Le serveur de messagerie sera mis à jour samedi de 8 h à 10 h. Aucune action n'est nécessaire de votre côté."),
    isPhishing: false,
    explanation: tr('Legitimate: the company domain, no link, no urgency, and nothing is asked from you.',
        "Légitime : le domaine de l'entreprise, aucun lien, aucune urgence, et rien ne t'est demandé."),
  ),
  PhishEmail(
    from: 'hr@corp-lan.com',
    subject: tr('Team lunch on Friday', "Déjeuner d'équipe vendredi"),
    body: tr('The team lunch is on Friday at 12:30 in the cafeteria. Reply to this email if you have food allergies.',
        "Le déjeuner d'équipe a lieu vendredi à 12 h 30 à la cafétéria. Répondez à cet e-mail si vous avez des allergies alimentaires."),
    isPhishing: false,
    explanation: tr('Legitimate: an internal sender, a normal request, no link and no personal data asked for.',
        'Légitime : un expéditeur interne, une demande normale, aucun lien et aucune donnée personnelle demandée.'),
  ),
  PhishEmail(
    from: 'security@corp-lan.com',
    subject: tr('Reminder: report suspicious emails', 'Rappel : signalez les e-mails suspects'),
    body: tr('If an email looks strange, do not click. Use the "Report phishing" button in your mailbox.',
        "Si un e-mail vous semble étrange, ne cliquez pas. Utilisez le bouton « Signaler un phishing » de votre messagerie."),
    isPhishing: false,
    explanation: tr('Legitimate: the security team from the company domain, giving advice without any link to click.',
        "Légitime : l'équipe sécurité, depuis le domaine de l'entreprise, donne un conseil sans aucun lien à cliquer."),
  ),
];
