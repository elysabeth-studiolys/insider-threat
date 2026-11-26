/// Core domain types: teams, roles, players, outcomes.
library;

import '../i18n.dart';

enum Team { red, blue, purple }

extension TeamX on Team {
  String get label => switch (this) {
        Team.red => 'Red Team',
        Team.blue => 'Blue Team',
        Team.purple => 'Purple Team',
      };
}

enum RoleId {
  red,
  defender,
  threatHunter,
  socAnalyst,
  incidentResponder,
  deadMansSwitch,
  networkEngineer,
  purple,
}

class RoleInfo {
  const RoleInfo({
    required this.id,
    required this.name,
    required this.team,
    required this.character,
    required this.werewolf,
    required this.tagline,
    required this.wakes,
    required this.power,
    this.unique = true,
  });

  final RoleId id;
  final String name;
  final Team team;

  /// Character name printed on the physical card.
  final String character;

  /// Matching role in the original Werewolf game.
  final String werewolf;
  final String tagline;
  final String wakes;
  final String power;

  /// Only one card of this role exists in a game.
  final bool unique;
}

/// Role names stay in English in both languages: they match the printed cards.
/// Built on each access so the texts follow the current language.
Map<RoleId, RoleInfo> get roleInfos => {
  RoleId.red: RoleInfo(
    id: RoleId.red,
    name: 'Red Team',
    team: Team.red,
    character: 'GHOSTLOAD',
    werewolf: tr('Werewolf', 'Loup-garou'),
    tagline: tr('The hooded infiltrator with a rogue USB key.', "L'infiltré encapuchonné, clé USB piégée en poche."),
    wakes: tr('Every night, together.', 'Chaque nuit, ensemble.'),
    power: tr(
        'Know each other. Each night they silently agree on one employee to compromise. They cannot target a fellow Red Team member.',
        "Ils se connaissent. Chaque nuit, ils choisissent en silence un employé à compromettre. Ils ne peuvent pas viser un membre de la Red Team."),
    unique: false,
  ),
  RoleId.defender: RoleInfo(
    id: RoleId.defender,
    name: 'Defender',
    team: Team.blue,
    character: 'BULWARK',
    werewolf: tr('Villager', 'Simple villageois'),
    tagline: tr('The frontline guard, shield up.', 'Le garde en première ligne, bouclier levé.'),
    wakes: tr('Never.', 'Jamais.'),
    power: tr('No special power. Wins through logic, observation and the vote.',
        "Aucun pouvoir spécial. Gagne grâce à la logique, l'observation et le vote."),
    unique: false,
  ),
  RoleId.threatHunter: RoleInfo(
    id: RoleId.threatHunter,
    name: 'Threat Hunter',
    team: Team.blue,
    character: 'TRACER',
    werewolf: tr('Seer', 'Voyante'),
    tagline: tr('The seeker, radar always on.', 'Le chercheur, radar toujours allumé.'),
    wakes: tr('Every night.', 'Chaque nuit.'),
    power: tr("Points at one player. The Narrator silently shows them that player's role card.",
        'Désigne un joueur. Le Narrateur lui montre en silence la carte de ce joueur.'),
  ),
  RoleId.socAnalyst: RoleInfo(
    id: RoleId.socAnalyst,
    name: 'SOC Analyst',
    team: Team.blue,
    character: 'NIGHTWATCH',
    werewolf: tr('Little Girl', 'Petite fille'),
    tagline: tr('The 24/7 monitoring operator.', "L'opératrice de surveillance, 24 h/24."),
    wakes: tr('Never called, may peek.', 'Jamais appelée, peut espionner.'),
    power: tr("May slightly open their eyes during the Red Team's turn. If caught, the Red Team may target them.",
        "Peut entrouvrir les yeux pendant le tour de la Red Team. Si elle se fait repérer, la Red Team peut la viser."),
  ),
  RoleId.incidentResponder: RoleInfo(
    id: RoleId.incidentResponder,
    name: 'Incident Responder',
    team: Team.blue,
    character: 'RESPAWN',
    werewolf: tr('Witch', 'Sorcière'),
    tagline: tr('Backup case in one hand, kill switch in the other.',
        "Une mallette de sauvegarde dans une main, l'arrêt d'urgence dans l'autre."),
    wakes: tr('Every night, after the Red Team.', 'Chaque nuit, après la Red Team.'),
    power: tr(
        "Sees tonight's victim. Two single-use tools: Backup Restore (save the victim) and Kill Process (eliminate any player). Each once per game; they may save themselves.",
        "Voit la victime de la nuit. Deux outils à usage unique : Backup Restore (sauver la victime) et Kill Process (éliminer n'importe quel joueur). Chacun une fois par partie ; elle peut se sauver elle-même."),
  ),
  RoleId.deadMansSwitch: RoleInfo(
    id: RoleId.deadMansSwitch,
    name: 'Dead Man\'s Switch',
    team: Team.blue,
    character: 'FAILSAFE',
    werewolf: tr('Hunter', 'Chasseur'),
    tagline: tr('Armed, timer at 00:00.', 'Armé, minuteur à 00:00.'),
    wakes: tr('Only when eliminated.', 'Seulement quand il est éliminé.'),
    power: tr('When it goes down, it immediately takes one player of its choice down with it.',
        "Quand il tombe, il emporte immédiatement un joueur de son choix avec lui."),
  ),
  RoleId.networkEngineer: RoleInfo(
    id: RoleId.networkEngineer,
    name: 'Network Engineer',
    team: Team.blue,
    character: 'LINKSMITH',
    werewolf: tr('Cupid', 'Cupidon'),
    tagline: tr('Cable on the shoulder, RJ45 in hand.', "Câble sur l'épaule, RJ45 à la main."),
    wakes: tr('First night only.', 'Première nuit seulement.'),
    power: tr(
        'Links two players with a VPN Tunnel. If one goes down, the other goes down too. Linked players never vote against each other.',
        "Relie deux joueurs par un VPN Tunnel. Si l'un tombe, l'autre tombe aussi. Les joueurs liés ne votent jamais l'un contre l'autre."),
  ),
  RoleId.purple: RoleInfo(
    id: RoleId.purple,
    name: 'Purple Team',
    team: Team.purple,
    character: 'DUALBOOT',
    werewolf: tr('White Werewolf', 'Loup blanc'),
    tagline: tr('Half red, half blue, loyal to no one.', 'Moitié rouge, moitié bleu, fidèle à personne.'),
    wakes: tr('Every night with the Red Team + alone every second night.',
        'Chaque nuit avec la Red Team, et seul une nuit sur deux.'),
    power: tr(
        'Seen by the Red Team as one of their own. Every second night it may eliminate one Red Team member. Wins by being the last player standing.',
        "La Red Team le prend pour l'un des siens. Une nuit sur deux, il peut éliminer un membre de la Red Team. Il gagne s'il est le dernier joueur en jeu."),
  ),
};

extension RoleIdX on RoleId {
  RoleInfo get info => roleInfos[this]!;
}

/// Order used when listing roles in pickers and the rules screen.
const List<RoleId> roleDisplayOrder = [
  RoleId.red,
  RoleId.threatHunter,
  RoleId.incidentResponder,
  RoleId.networkEngineer,
  RoleId.deadMansSwitch,
  RoleId.socAnalyst,
  RoleId.defender,
  RoleId.purple,
];

class Player {
  Player({required this.id, required this.name, required this.role});

  final int id;
  String name;
  RoleId role;
  bool alive = true;

  Team get team => role.info.team;
}

enum Winner { blue, red, purple, vpn, outage }
