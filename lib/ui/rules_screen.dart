import 'dart:math';

import 'package:flutter/material.dart';

import '../game/events.dart';
import '../i18n.dart';
import '../game/models.dart';
import '../theme/app_theme.dart';
import 'role_card_face.dart';
import 'widgets.dart';

/// The two views of the Rules screen.
enum RulesTab { rules, roles }

/// Game rules and role list, opened from the Rules button on the home screen.
/// A select at the top switches between the two views.
class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key, this.initialTab = RulesTab.rules});

  final RulesTab initialTab;

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  late RulesTab _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    return NeonBackground(
      mood: Mood.night,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
            // The arrow, the title and the space around them all go back.
            child: Semantics(
              button: true,
              label: tr('Back', 'Retour'),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.of(context).maybePop(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back_rounded, color: AppColors.text),
                      const SizedBox(width: 12),
                      ExcludeSemantics(
                        child: Text(tr('Rules', 'Règles').toUpperCase(), style: AppText.ui(32, weight: FontWeight.w700)),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: RulesTabSelect(
              value: _tab,
              onChanged: (t) => setState(() => _tab = t),
            ),
          ),
          Expanded(
            child: switch (_tab) {
              RulesTab.rules => const _RulesView(key: PageStorageKey('rules')),
              RulesTab.roles => const _RolesView(key: PageStorageKey('roles')),
            },
          ),
        ],
      ),
    );
  }
}

/// Two-option select: game rules or roles.
class RulesTabSelect extends StatelessWidget {
  const RulesTabSelect({super.key, required this.value, required this.onChanged});

  final RulesTab value;
  final ValueChanged<RulesTab> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(RulesTab tab, String label) {
      final selected = tab == value;
      final radius = BorderRadius.circular(12);
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: Material(
            color: Colors.transparent,
            child: Ink(
              height: 44,
              decoration: BoxDecoration(
                gradient: selected ? AppColors.primaryGradient : null,
                borderRadius: radius,
              ),
              child: InkWell(
                borderRadius: radius,
                onTap: selected ? null : () => onChanged(tab),
                child: Center(
                  child: Text(
                    label.toUpperCase(),
                    style: AppText.body(
                      14,
                      weight: FontWeight.w700,
                      spacing: .9,
                      color: selected ? AppColors.onAccent : AppColors.textSoft,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          option(RulesTab.rules, tr('Game rules', 'Règles du jeu')),
          const SizedBox(width: 4),
          option(RulesTab.roles, tr('Roles', 'Rôles')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- building blocks

const _pad = EdgeInsets.fromLTRB(20, 8, 20, 40);

class _H extends StatelessWidget {
  const _H(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(text.toUpperCase(), style: AppText.ui(26, weight: FontWeight.w700)),
      );
}

class _Sub extends StatelessWidget {
  const _Sub(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(text,
            style: AppText.body(16, weight: FontWeight.w700, color: AppColors.primarySoft)),
      );
}

TextStyle get _bodyStyle =>
    AppText.body(15, weight: FontWeight.w400, color: AppColors.textSoft, height: 1.5);

/// Paragraph. Words wrapped in `**double stars**` are highlighted.
class _P extends StatelessWidget {
  const _P(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text.rich(TextSpan(children: richSpans(text, _bodyStyle, AppColors.text))),
      );
}

/// Splits `a **b** c` into spans, the starred parts bold in [accent].
List<TextSpan> richSpans(String text, TextStyle base, Color accent) {
  final parts = text.split('**');
  final bold = base.copyWith(
    color: accent,
    fontWeight: FontWeight.w700,
    fontVariations: const [FontVariation('wght', 700)],
  );
  return [
    for (var i = 0; i < parts.length; i++)
      TextSpan(text: parts[i], style: i.isOdd ? bold : base),
  ];
}

/// Bulleted (marker null) or numbered list.
class _List extends StatelessWidget {
  const _List(this.items, {this.numbered = false});
  final List<String> items;
  final bool numbered;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 26,
                    child: numbered
                        ? Text('${i + 1}'.padLeft(2, '0'),
                            style: AppText.mono(13, color: AppColors.primary, height: 1.75))
                        : Padding(
                            padding: const EdgeInsets.only(top: 9),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                  ),
                  Expanded(
                    child: Text.rich(
                        TextSpan(children: richSpans(items[i], _bodyStyle, AppColors.text))),
                  ),
                ],
              ),
            ),
        ],
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.accent, this.margin = const EdgeInsets.only(bottom: 10)});
  final Widget child;
  final Color? accent;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accent == null ? AppColors.line : accent!.withValues(alpha: .45),
          ),
        ),
        child: child,
      );
}

/// Small coloured label, e.g. "HELPS BLUE TEAM".
class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text.toUpperCase(),
            style: AppText.body(11, weight: FontWeight.w700, color: color, spacing: .6)),
      );
}

Color sideColor(EventSide s) => switch (s) {
      EventSide.blue => AppColors.teamBlue,
      EventSide.red => AppColors.teamRed,
      EventSide.chaos => AppColors.primary,
    };

// ---------------------------------------------------------------- game rules

class _RulesView extends StatelessWidget {
  const _RulesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _pad,
      children: [
        // 1. Goal
        _H(tr('The goal', 'Le but')),
        _P(tr(
            'The game takes place in **CORP-LAN**, a company and its network. Each player is an '
                '**employee** with a secret **role**. Hidden attackers, the **Red Team**, are among the '
                'defenders, the **Blue Team**.',
            "La partie se déroule dans **CORP-LAN**, une entreprise et son réseau. Chaque joueur est un "
                "**employé** avec un **rôle** secret. Des attaquants cachés, la **Red Team**, se trouvent parmi les "
                "défenseurs, la **Blue Team**.")),
        _P(tr(
            'Every night, the Red Team compromises one employee (their account and computer). '
                'Every day, everyone debates and votes to put one suspect in quarantine. Find the attackers '
                'before they take over the company.',
            "Chaque nuit, la Red Team compromet un employé (son compte et son ordinateur). "
                "Chaque jour, tout le monde débat et vote pour mettre un suspect en quarantaine. Trouvez les attaquants "
                "avant qu'ils ne prennent le contrôle de l'entreprise.")),

        // 2. Players
        _H(tr('Players and material', 'Joueurs et matériel')),
        _List([
          tr('**5 to 14 players** + 1 **Narrator** who runs the game and does not play.',
              '**5 à 14 joueurs** + 1 **Narrateur** qui mène la partie et ne joue pas.'),
          tr('1 role card per player.', '1 carte de rôle par joueur.'),
          tr('10 Event cards, each with a quiz question (Expert mode).',
              '10 cartes Event, chacune avec une question de quiz (mode Expert).'),
          tr('This app: script for the Narrator, timers, quiz and game tracking.',
              'Cette appli : le script du Narrateur, les chronos, le quiz et le suivi de la partie.'),
          tr('A game lasts **15 to 40 minutes**.', 'Une partie dure **15 à 40 minutes**.'),
        ]),

        // 3. Teams
        _H(tr('Teams and how to win', 'Équipes et victoire')),
        for (final w in _wins)
          _Panel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: w.team == null
                      ? const Icon(Icons.link_rounded, size: 14, color: AppColors.muted)
                      : TeamPerson(w.team!),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.name.toUpperCase(), style: AppText.ui(20, weight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(w.condition, style: _bodyStyle),
                      if (w.tag != null) ...[
                        const SizedBox(height: 6),
                        Text(w.tag!,
                            style: AppText.mono(11,
                                color: w.team == null
                                    ? AppColors.muted
                                    : AppColors.team(w.team!))),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        _P(tr('If every remaining player goes down at the same time, nobody wins: **total outage**.',
            'Si tous les joueurs restants tombent en même temps, personne ne gagne : **panne totale**.')),

        // 4. Setup
        _H(tr('Setup', 'Mise en place')),
        _List([
          tr('Players sit in a circle. The Narrator sits where they can see everyone.',
              'Les joueurs s’assoient en cercle. Le Narrateur se place de façon à voir tout le monde.'),
          tr('The Narrator enters the players in this app. The app recommends the composition '
                  '(about 1 attacker for every 4 players).',
              "Le Narrateur saisit les joueurs dans l'appli. L'appli conseille la composition "
                  '(environ 1 attaquant pour 4 joueurs).'),
          tr('The Narrator deals one role card face down to each player. Players look at their card '
                  'and keep it face down.',
              'Le Narrateur distribue une carte de rôle face cachée à chaque joueur. Chacun regarde sa carte '
                  'et la garde face cachée.'),
          tr('The Narrator starts the first night.', 'Le Narrateur lance la première nuit.'),
        ], numbered: true),

        // 5. Game flow
        _H(tr('How a game works', "Déroulement d'une partie")),
        _P(tr('The game alternates between night (**Attack Phase**) and day (**Incident Review**) '
                'until a team wins.',
            "La partie alterne entre la nuit (**Attack Phase**) et le jour (**Incident Review**) "
                "jusqu'à la victoire d'une équipe.")),
        _Sub(tr('Night 1', 'Nuit 1')),
        _List([
          tr('Everyone closes their eyes.', 'Tout le monde ferme les yeux.'),
          tr('**Network Engineer**: points at 2 players. The Narrator taps them; they open their eyes, '
                  'recognise each other, then close them.',
              '**Network Engineer** : désigne 2 joueurs. Le Narrateur les touche ; ils ouvrent les yeux, '
                  'se reconnaissent, puis les referment.'),
          tr('**Threat Hunter**: points at a player and sees their card.',
              '**Threat Hunter** : désigne un joueur et voit sa carte.'),
          tr('**Red Team** (with the Purple Team): silently agree on a target and point at it. '
                  'The SOC Analyst may peek.',
              '**Red Team** (avec la Purple Team) : choisit une cible en silence et la désigne. '
                  'La SOC Analyst peut espionner.'),
          tr('**Incident Responder**: sees the victim. Thumb up or down for Backup Restore, '
                  'and may point at a player for Kill Process.',
              '**Incident Responder** : voit la victime. Pouce levé ou baissé pour Backup Restore, '
                  'et peut désigner un joueur pour Kill Process.'),
        ], numbered: true),
        _Sub(tr('Following nights', 'Nuits suivantes')),
        _List([
          tr('**Threat Hunter**: inspects a player.', '**Threat Hunter** : inspecte un joueur.'),
          tr('**Red Team** (with the Purple Team): choose a target.', '**Red Team** (avec la Purple Team) : choisit une cible.'),
          tr('**Purple Team**, alone, every second night: may eliminate a Red Team member.',
              '**Purple Team**, seule, une nuit sur deux : peut éliminer un membre de la Red Team.'),
          tr('**Incident Responder**: may use their remaining powers.',
              '**Incident Responder** : peut utiliser les pouvoirs qui lui restent.'),
        ], numbered: true),
        _Sub(tr('Day', 'Jour')),
        _List([
          tr('**Morning report**: the Narrator says who was compromised. Eliminated players show their card.',
              '**Rapport du matin** : le Narrateur annonce qui a été compromis. Les joueurs éliminés montrent leur carte.'),
          tr("**Chain reactions**: Dead Man's Switch, VPN Tunnel.", "**Réactions en chaîne** : Dead Man's Switch, VPN Tunnel."),
          tr('**Day 1 only**: elect the CISO.', '**Jour 1 seulement** : élection du RSSI.'),
          tr('**Expert mode, from Day 2**: Event + quiz (see below).',
              '**Mode Expert, à partir du jour 2** : Event + quiz (voir plus bas).'),
          tr('**Debate**, then **vote**: on "3, 2, 1", everyone points at a player. Most votes = '
                  "quarantined. The CISO's vote counts double.",
              '**Débat**, puis **vote** : à « 3, 2, 1 », chacun désigne un joueur. Le plus de voix = '
                  'mis en quarantaine. La voix du RSSI compte double.'),
          tr('**Tie**: the CISO decides. Without a CISO, nobody is quarantined.',
              "**Égalité** : le RSSI tranche. Sans RSSI, personne n'est mis en quarantaine."),
          tr('The quarantined player shows their card. Chain reactions apply. If no team has won, '
                  'night falls again.',
              "Le joueur mis en quarantaine montre sa carte. Les réactions en chaîne s'appliquent. Si aucune équipe n'a gagné, "
                  'la nuit retombe.'),
        ], numbered: true),
        _Sub(tr('Eliminated players', 'Joueurs éliminés')),
        _List([
          tr('Show their role card.', 'Montrent leur carte de rôle.'),
          tr('Stay silent: no hints, no reactions, no vote, no quiz answer.',
              'Se taisent : pas d’indice, pas de réaction, pas de vote, pas de réponse au quiz.'),
          tr('Keep their eyes closed at night.', 'Gardent les yeux fermés la nuit.'),
        ]),

        // 6. Narrator
        _H(tr('Narrator tips', 'Conseils au Narrateur')),
        _List([
          tr('At night, players never speak: they point, and the Narrator nods.',
              'La nuit, les joueurs ne parlent jamais : ils désignent, et le Narrateur hoche la tête.'),
          tr('Call every role that was dealt, even if its player is out. Wait a few seconds each time.',
              'Appelez chaque rôle distribué, même si son joueur est éliminé. Attendez quelques secondes à chaque fois.'),
          tr("Same tone and same timing every time. Don't look at the players who are acting.",
              'Même ton et même rythme à chaque fois. Ne regardez pas les joueurs qui agissent.'),
        ]),

        // 7. Expert mode
        _H(tr('Expert mode: Events and quiz', 'Mode Expert : Events et quiz')),
        _P(tr(
            'In Expert mode, each day starts with an **Event** based on a real cyber threat. An Event '
                "is not just a card that appears: it comes with a **quiz question**, and the players' "
                'answers decide what happens.',
            'En mode Expert, chaque jour commence par un **Event** inspiré d’une vraie menace cyber. Un Event '
                "n'est pas juste une carte qui apparaît : il vient avec une **question de quiz**, et les réponses "
                'des joueurs décident de ce qui se passe.')),
        _Sub(tr('How an Event works', 'Comment se déroule un Event')),
        _List([
          tr('From Day 2, after the morning report, the app draws an Event. The Narrator reads its name.',
              "À partir du jour 2, après le rapport du matin, l'appli tire un Event. Le Narrateur lit son nom."),
          tr('The app shows a **quiz question** about this threat, with **3 answers**. The Narrator reads it.',
              "L'appli affiche une **question de quiz** sur cette menace, avec **3 réponses**. Le Narrateur la lit."),
          tr('Players think for 1 minute without talking.', 'Les joueurs réfléchissent 1 minute sans parler.'),
          tr('On "3, 2, 1", every player still in the game shows **1, 2 or 3 fingers** at the same time.',
              'À « 3, 2, 1 », chaque joueur encore en jeu montre **1, 2 ou 3 doigts** en même temps.'),
          tr('The app shows the right answer and a short explanation.',
              "L'appli affiche la bonne réponse et une courte explication."),
          tr('The result decides the Event.', "Le résultat décide de l'Event."),
        ], numbered: true),
        _Sub(tr('What the quiz changes', 'Ce que change le quiz')),
        for (final r in _quizResults)
          _Panel(
            accent: sideColor(r.side),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Badge(r.side.label, sideColor(r.side)),
                const SizedBox(height: 8),
                Text.rich(TextSpan(children: richSpans(r.text, _bodyStyle, AppColors.text))),
              ],
            ),
          ),
        _P(tr(
            '**Tip:** everyone sees who answered what. A Red Team player may answer wrong on purpose '
                'to block a Blue Event or let a Red Event happen... but that can give them away during the '
                'debate!',
            '**Astuce :** tout le monde voit qui a répondu quoi. Un joueur de la Red Team peut se tromper exprès '
                'pour bloquer un Event bleu ou laisser passer un Event rouge… mais ça peut le trahir pendant le '
                'débat !')),
        _Sub(tr('The 10 Events', 'Les 10 Events')),
        for (final card in EventCard.values) _EventTile(card),
      ],
    );
  }
}

class _Win {
  const _Win(this.team, this.name, this.condition, [this.tag]);
  final Team? team;
  final String name;
  final String condition;
  final String? tag;
}

List<_Win> get _wins => [
  _Win(Team.blue, 'Blue Team',
      tr('All Red Team and Purple Team players are eliminated.', 'Tous les joueurs Red Team et Purple Team sont éliminés.'),
      'NETWORK SECURED'),
  _Win(Team.red, 'Red Team', tr('Only Red Team players are left.', 'Il ne reste que des joueurs Red Team.'), 'NETWORK BREACHED'),
  _Win(Team.purple, 'Purple Team',
      tr('A lone double agent. Wins if it is the last player standing.',
          "Un agent double solitaire. Gagne s'il est le dernier joueur en jeu."),
      'SOLO WIN'),
  _Win(null, 'VPN Tunnel',
      tr('Two linked players from different teams win if they are the last two players standing.',
          "Deux joueurs reliés, d'équipes différentes, gagnent s'ils sont les deux derniers en jeu.")),
];

class _QuizResult {
  const _QuizResult(this.side, this.text);
  final EventSide side;
  final String text;
}

List<_QuizResult> get _quizResults => [
  _QuizResult(EventSide.blue,
      tr('The Event happens **only if more than half** of the players are right. Knowledge gives the defenders an advantage.',
          "L'Event a lieu **seulement si plus de la moitié** des joueurs ont juste. Le savoir donne l'avantage aux défenseurs.")),
  _QuizResult(EventSide.red,
      tr('If **more than half** of the players are right, the company was ready: the Event is **blocked**. Otherwise, it happens.',
          "Si **plus de la moitié** des joueurs ont juste, l'entreprise était prête : l'Event est **bloqué**. Sinon, il a lieu.")),
  _QuizResult(EventSide.chaos, tr('The Event **always happens**. The quiz is still played.',
      "L'Event **a toujours lieu**. Le quiz est quand même joué.")),
  _QuizResult(EventSide.chaos,
      tr('**Phishing Campaign** is special: the quiz shows an email, legitimate or phishing. **Majority right**: malus for the Red Team, their attack fails tonight. **Majority wrong**: bonus for the Red Team, they compromise 2 machines tonight.',
          "**Phishing Campaign** est spécial : le quiz affiche un e-mail, légitime ou phishing. **Majorité juste** : malus pour la Red Team, son attaque échoue cette nuit. **Majorité fausse** : bonus pour la Red Team, elle compromet 2 machines cette nuit.")),
];

class _EventTile extends StatelessWidget {
  const _EventTile(this.card);
  final EventCard card;

  @override
  Widget build(BuildContext context) {
    final info = card.info;
    final color = sideColor(info.side);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(info.number.toString().padLeft(2, '0'),
                  style: AppText.mono(13, color: color)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(info.title.toUpperCase(), style: AppText.ui(20, weight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Badge(info.side.label, color),
              _Badge(card.face.when, AppColors.muted),
            ],
          ),
          const SizedBox(height: 10),
          Text(info.description,
              style: AppText.body(14,
                  weight: FontWeight.w400, color: AppColors.muted, height: 1.45)),
          const SizedBox(height: 6),
          Text.rich(TextSpan(children: richSpans(card.face.effect, _bodyStyle, color))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- roles

class _RolesView extends StatelessWidget {
  const _RolesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _pad,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: _P(tr('Each player secretly gets one role card. Here is every role, its power and its match in the original Werewolf game.',
              'Chaque joueur reçoit en secret une carte de rôle. Voici chaque rôle, son pouvoir et son équivalent dans le Loup-Garou.')),
        ),
        for (final id in roleDisplayOrder) _FlipRoleCard(info: id.info),
        const _CisoTile(),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 92, child: Lbl(label)),
            Expanded(child: Text(value, style: _bodyStyle)),
          ],
        ),
      );
}

class _RoleTile extends StatelessWidget {
  const _RoleTile(this.info, {this.onFlip, this.margin = const EdgeInsets.only(bottom: 10)});
  final RoleInfo info;

  /// When set, a left arrow turns the card over to show the character.
  final VoidCallback? onFlip;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.team(info.team);
    return _Panel(
      accent: color,
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TeamPerson(info.team),
              const SizedBox(width: 10),
              Expanded(child: Text(info.name.toUpperCase(), style: AppText.ui(22, weight: FontWeight.w700))),
              if (onFlip != null) ...[
                const SizedBox(width: 4),
                _FlipButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: tr('Show the character', 'Voir le personnage'),
                  color: color,
                  onTap: onFlip!,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // Team badge where the nickname used to be.
          _Badge(info.team.label, color),
          const SizedBox(height: 6),
          Text(info.tagline,
              style: AppText.body(13,
                  weight: FontWeight.w400, color: AppColors.muted, height: 1.4)),
          const SizedBox(height: 4),
          _InfoRow(tr('Werewolf', 'Loup-Garou'), info.werewolf),
          _InfoRow(tr('Wakes up', 'Se réveille'), info.wakes),
          _InfoRow(tr('Power', 'Pouvoir'), info.power),
        ],
      ),
    );
  }
}

/// The CISO is a title given on Day 1, not a role card.
class _CisoTile extends StatelessWidget {
  const _CisoTile();

  @override
  Widget build(BuildContext context) => _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.textSoft),
                const SizedBox(width: 8),
                Expanded(child: Text(tr('CISO', 'RSSI (CISO)'), style: AppText.ui(22, weight: FontWeight.w700))),
              ],
            ),
            const SizedBox(height: 10),
            _Badge(tr('Title', 'Titre'), AppColors.textSoft),
            const SizedBox(height: 6),
            Text(tr('The one who signs off on everything.', 'Celui qui valide tout.'),
                style: AppText.body(13,
                    weight: FontWeight.w400, color: AppColors.muted, height: 1.4)),
            const SizedBox(height: 4),
            _InfoRow(tr('Werewolf', 'Loup-Garou'), tr('Captain / Mayor', 'Capitaine / Maire')),
            _InfoRow(tr('Given', 'Attribué'), tr('Elected by everyone on Day 1, on top of their secret role.',
                'Élu par tous le jour 1, en plus de son rôle secret.')),
            _InfoRow(tr('Power', 'Pouvoir'), tr('Double vote, breaks ties. When eliminated, names their successor.',
                'Voix double, départage les égalités. Quand il est éliminé, il nomme son successeur.')),
          ],
        ),
      );
}



class _FlipButton extends StatelessWidget {
  const _FlipButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: color.withValues(alpha: .16),
          minimumSize: const Size(40, 40),
        ),
        icon: Icon(icon, color: color, size: 20),
      );
}

/// A role card that turns over to its character side, and back, with a
/// short, light flip. Tap anywhere on it (or its arrow) to turn it.
class _FlipRoleCard extends StatefulWidget {
  const _FlipRoleCard({required this.info});

  final RoleInfo info;

  @override
  State<_FlipRoleCard> createState() => _FlipRoleCardState();
}

class _FlipRoleCardState extends State<_FlipRoleCard> with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
  );

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _toggle() {
    // Showing the front, or on its way back to it: turn to the character.
    final toBack = _flip.status == AnimationStatus.dismissed ||
        _flip.status == AnimationStatus.reverse;
    if (MediaQuery.disableAnimationsOf(context)) {
      _flip.value = toBack ? 1 : 0;
    } else if (toBack) {
      _flip.forward();
    } else {
      _flip.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final front = _RoleTile(widget.info, onFlip: _toggle, margin: EdgeInsets.zero);
    final back = RoleCardFace(
      info: widget.info,
      trailing: _FlipButton(
        icon: Icons.arrow_forward_rounded,
        tooltip: tr('Back to the role', 'Retour au rôle'),
        color: AppColors.team(widget.info.team),
        onTap: _toggle,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      // Tap anywhere on the card to turn it over.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: ConstrainedBox(
          // Tall enough for the full-length character.
          constraints: const BoxConstraints(minHeight: 420),
          child: AnimatedBuilder(
            animation: _flip,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_flip.value);
              final showBack = t >= .5;
              // Turns towards the left. Past halfway the back side is shown,
              // mirrored back so it reads the right way round.
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, .001)
                  ..rotateY(-pi * t),
                // Both sides keep the same size: the front sets it.
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    Visibility(
                      visible: !showBack,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: front,
                    ),
                    if (showBack)
                      Positioned.fill(
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(pi),
                          child: back,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
