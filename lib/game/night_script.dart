part of 'game_controller.dart';

String get _waitLine => tr('Nobody can use this power. Read the line anyway and wait a few seconds.',
    'Personne ne peut utiliser ce pouvoir. Lisez quand même la phrase et attendez quelques secondes.');

/// Attackers still online: Red Team and the Purple double agent.
List<Player> _attackersOf(GameController c) =>
    c.players.where((p) => p.alive && p.team != Team.blue).toList();

/// The night order for tonight. Roles that were dealt are always called, even
/// when their holder is out, so that silence never gives anything away. Roles
/// that were not dealt are never called.
List<(StepKind, int)> _nightPlan(GameController c) {
  final ev = c.nightEvent;
  final outage = ev == EventCard.powerOutage;
  final plan = <(StepKind, int)>[(StepKind.nightfall, 0)];
  if (c.night == 1 && c.inPlay.contains(RoleId.networkEngineer)) {
    plan
      ..add((StepKind.engineer, 0))
      ..add((StepKind.linked, 0));
  }
  if (!outage && c.inPlay.contains(RoleId.threatHunter)) {
    plan.add((StepKind.hunter, 0));
  }
  // Phishing spotted: the Red Team's attack fails, they are not called.
  final phishBlocked = ev == EventCard.phishing && c.phishSpotted;
  if (ev == EventCard.c2ServerDown) {
    for (final a in _attackersOf(c)) {
      plan.add((StepKind.redSolo, a.id));
    }
  } else if (!phishBlocked) {
    plan.add((StepKind.red, 0));
  }
  if (!outage && c.night.isEven && c.inPlay.contains(RoleId.purple)) {
    plan.add((StepKind.purple, 0));
  }
  if (!outage && c.inPlay.contains(RoleId.incidentResponder)) {
    plan.add((StepKind.responder, 0));
  }
  plan.add((StepKind.dawn, 0));
  return plan;
}

GuideStep _buildNight(GameController c) {
  final plan = _nightPlan(c);
  final i = min(c.nightCursor, plan.length - 1);
  final (kind, arg) = plan[i];
  final stepNo = i + 1;
  final total = plan.length;
  final canBack = i > 0;
  final ev = c.nightEvent;

  Player? holder(RoleId r) => c.holder(r);
  bool gone(Player? p) => p == null || !p.alive;

  switch (kind) {
    case StepKind.nightfall:
      final hp = c.honeypotId;
      return GuideStep(
        kind: kind,
        kicker: tr('Everyone', 'Tout le monde'),
        title: tr('Nightfall', 'La nuit tombe'),
        tag: ev == null ? null : tr('Event: ${ev.info.title}', 'Événement : ${ev.info.title}'),
        say: tr('Night falls on CORP-LAN. All employees, log off and close your eyes.',
                'La nuit tombe sur CORP-LAN. Tous les employés, déconnectez-vous et fermez les yeux.') +
            (ev == EventCard.powerOutage
                ? tr(' Power outage: all special powers are offline tonight.',
                    ' Coupure de courant : tous les pouvoirs spéciaux sont hors ligne cette nuit.')
                : '') +
            (ev == EventCard.phishing
                ? (c.phishSpotted
                    ? tr(' The phishing campaign was spotted: the Red Team will not attack tonight.',
                        " La campagne de phishing a été repérée : la Red Team n'attaquera pas cette nuit.")
                    : tr(' The phishing campaign worked: tonight the Red Team strikes twice.',
                        ' La campagne de phishing a marché : cette nuit, la Red Team frappe deux fois.'))
                : ''),
        todo: tr(
            'The night ambience starts by itself. Wait until the table is silent. Players never speak at night: they point.',
            "L'ambiance de nuit démarre toute seule. Attendez que la table soit silencieuse. La nuit, les joueurs ne parlent jamais : ils désignent du doigt."),
        secret: hp == null
            ? null
            : tr('Honeypot decoy: ${c.players[hp].name}. If the Red Team targets this machine tonight, the attack fails. Tell nobody.',
                'Leurre du Honeypot : ${c.players[hp].name}. Si la Red Team vise cette machine cette nuit, l\'attaque échoue. Ne le dites à personne.'),
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    case StepKind.engineer:
      final ne = holder(RoleId.networkEngineer);
      final out = gone(ne);
      return GuideStep(
        kind: kind,
        kicker: out ? tr('Read it anyway', 'Lisez quand même') : ne!.name,
        title: 'Network Engineer',
        team: Team.blue,
        tag: out ? tr('Eliminated', 'Éliminé') : null,
        say: tr(
            'Network Engineer, wake up. Point at two machines to link with a VPN tunnel. Network Engineer, go back to sleep.',
            'Network Engineer, réveille-toi. Désigne deux machines à relier par un tunnel VPN. Network Engineer, rendors-toi.'),
        todo: out
            ? _waitLine
            : tr('${ne!.name} points at two machines (they may include themselves). Tap both.',
                '${ne!.name} désigne deux machines (il peut se choisir lui-même). Touchez les deux.'),
        selKey: 'link',
        picker: out
            ? null
            : PickerSpec(
                label: tr('Pick two machines (${c.link.length}/2)', 'Choisissez deux machines (${c.link.length}/2)'),
                tiles: c._tiles(selected: c.link.toSet()),
                style: PickStyle.violet,
                max: 2,
              ),
        canContinue: out || c.link.length == 2,
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    case StepKind.linked:
      final linked = c.link.length == 2;
      final a = linked ? c.players[c.link[0]] : null;
      final b = linked ? c.players[c.link[1]] : null;
      return GuideStep(
        kind: kind,
        kicker: linked ? tr('${a!.name} and ${b!.name}', '${a!.name} et ${b!.name}') : tr('Nobody linked', 'Personne de relié'),
        title: tr('Linked machines', 'Machines reliées'),
        team: Team.purple,
        say: tr(
            'I will tap the two linked machines. Linked machines, open your eyes and recognise each other. If one of you goes down, the other goes down too. Close your eyes.',
            "Je vais toucher les deux machines reliées. Machines reliées, ouvrez les yeux et reconnaissez-vous. Si l'une de vous tombe, l'autre tombe aussi. Fermez les yeux."),
        todo: linked
            ? tr('Tap ${a!.name} and ${b!.name} on the shoulder. Let them see each other, then ask them to close their eyes.',
                "Touchez l'épaule de ${a!.name} et de ${b!.name}. Laissez-les se voir, puis demandez-leur de fermer les yeux.")
            : tr('Nobody is linked. Read the line anyway and wait a few seconds.',
                "Personne n'est relié. Lisez quand même la phrase et attendez quelques secondes."),
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    case StepKind.hunter:
      final th = holder(RoleId.threatHunter);
      final out = gone(th);
      final need = ev == EventCard.securityAudit ? 2 : 1;
      final picks = c.sel('hunter');
      return GuideStep(
        kind: kind,
        kicker: out ? tr('Read it anyway', 'Lisez quand même') : th!.name,
        title: 'Threat Hunter',
        team: Team.blue,
        tag: out ? tr('Eliminated', 'Éliminé') : null,
        say: need == 2
            ? tr('Threat Hunter, wake up. Tonight, you may inspect two machines. Point at the machines you want to inspect. Threat Hunter, go back to sleep.',
                'Threat Hunter, réveille-toi. Cette nuit, tu peux inspecter deux machines. Désigne les machines que tu veux inspecter. Threat Hunter, rendors-toi.')
            : tr('Threat Hunter, wake up. Point at the machine you want to inspect. Threat Hunter, go back to sleep.',
                'Threat Hunter, réveille-toi. Désigne la machine que tu veux inspecter. Threat Hunter, rendors-toi.'),
        todo: out
            ? _waitLine
            : need == 2
                ? tr('${th!.name} points at two players. Tap both: the cards appear on screen. Silently turn the phone towards ${th.name}, one card after the other.',
                    "${th!.name} désigne deux joueurs. Touchez-les : les cartes s'affichent. Tournez le téléphone vers ${th.name} en silence, une carte après l'autre.")
                : tr('${th!.name} points at a player. Tap that player: the card appears on screen. Silently turn the phone towards ${th.name}.',
                    "${th!.name} désigne un joueur. Touchez ce joueur : sa carte s'affiche. Tournez le téléphone vers ${th.name} en silence."),
        selKey: 'hunter',
        picker: out
            ? null
            : PickerSpec(
                label: need == 2
                    ? tr('Which machines? (${picks.length}/2)', 'Quelles machines ? (${picks.length}/2)')
                    : tr('Which machine?', 'Quelle machine ?'),
                tiles: c._tiles(
                  selected: picks.toSet(),
                  lock: (p) => p.id == th!.id,
                ),
                style: PickStyle.blue,
                max: need,
              ),
        results: out
            ? const []
            : [
                for (final id in picks)
                  ResultLine(
                    team: c.players[id].team,
                    text: tr(
                        'Show ${th!.name} the role card of ${c.players[id].name}: ${c.players[id].role.info.name} (${c.players[id].role.info.character})',
                        'Montrez à ${th!.name} la carte de ${c.players[id].name} : ${c.players[id].role.info.name} (${c.players[id].role.info.character})'),
                  ),
              ],
        reveal: out || picks.length < need
            ? const []
            : [
                for (final id in picks)
                  RevealCard(name: c.players[id].name, info: c.players[id].role.info),
              ],
        revealTo: out ? '' : th!.name,
        canContinue: out || picks.length >= need,
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    case StepKind.red:
      final attackers = _attackersOf(c);
      // Phishing worked: stolen credentials give the Red Team a second victim.
      final twice = ev == EventCard.phishing && !c.phishSpotted;
      final targets = c.players.where((p) => p.alive && p.team == Team.blue).length;
      final need = twice ? min(2, targets) : 1;
      return GuideStep(
        kind: kind,
        kicker: attackers.map((p) => p.name).join(', '),
        title: 'Red Team',
        team: Team.red,
        say: twice
            ? tr('Red Team, wake up. Look at each other. With the stolen credentials, silently choose two machines to compromise. Red Team, go back to sleep.',
                'Red Team, réveillez-vous. Regardez-vous. Avec les identifiants volés, choisissez en silence deux machines à compromettre. Red Team, rendormez-vous.')
            : tr('Red Team, wake up. Look at each other. Silently choose one machine to compromise. Red Team, go back to sleep.',
                'Red Team, réveillez-vous. Regardez-vous. Choisissez en silence une machine à compromettre. Red Team, rendormez-vous.'),
        todo: twice
            ? tr("They point at two players and you nod to confirm. Tap both. The first one is tonight's victim for the Incident Responder; the second cannot be restored. The SOC Analyst may peek.",
                "Ils désignent deux joueurs et vous hochez la tête pour confirmer. Touchez-les. Le premier est la victime de la nuit pour l'Incident Responder ; le second ne peut pas être restauré. La SOC Analyst peut espionner.")
            : tr('They point at a player and you nod to confirm. Tap the victim. ', 'Ils désignent un joueur et vous hochez la tête pour confirmer. Touchez la victime. ') +
                (ev == EventCard.powerOutage
                    ? tr('Power outage: the SOC Analyst cannot peek.', 'Coupure de courant : la SOC Analyst ne peut pas espionner.')
                    : tr('The SOC Analyst may peek.', 'La SOC Analyst peut espionner.')),
        selKey: 'red',
        picker: PickerSpec(
          label: twice
              ? tr("Tap the two victims (${c.sel('red').length}/2)", "Touchez les deux victimes (${c.sel('red').length}/2)")
              : tr('Tap the victim', 'Touchez la victime'),
          tiles: c._tiles(
            selected: c.sel('red').toSet(),
            lock: (p) => p.team != Team.blue,
          ),
          style: PickStyle.red,
          max: twice ? 2 : 1,
        ),
        canContinue: c.sel('red').length >= max(need, 1),
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    case StepKind.redSolo:
      final attackers = _attackersOf(c);
      final idx = attackers.indexWhere((p) => p.id == arg);
      final p = c.players[arg];
      final key = 'red:$arg';
      final isLast = idx == attackers.length - 1;
      String? outcome;
      if (isLast && attackers.every((a) => c.sel('red:${a.id}').isNotEmpty)) {
        final t = c.rawTarget;
        outcome = t == null
            ? tr('No agreement: the attack fails. Tonight is a quiet night.',
                "Pas d'accord : l'attaque échoue. La nuit est calme.")
            : tr('The attackers agree on ${c.players[t].name}.', "Les attaquants s'accordent sur ${c.players[t].name}.");
      }
      return GuideStep(
        kind: kind,
        kicker: tr('C2 server down · attacker ${idx + 1} of ${attackers.length}',
            'Serveur C2 tombé · attaquant ${idx + 1} sur ${attackers.length}'),
        title: p.name,
        team: p.team,
        sub: p.role.info.name,
        say: idx == 0
            ? tr("The attackers' C2 server is down. The attacker I tap, open your eyes and point at your target. Close your eyes.",
                "Le serveur C2 des attaquants est tombé. L'attaquant que je touche, ouvre les yeux et désigne ta cible. Ferme les yeux.")
            : tr('Next attacker, open your eyes and point at your target. Close your eyes.',
                'Attaquant suivant, ouvre les yeux et désigne ta cible. Ferme les yeux.'),
        todo: tr(
            'Tap ${p.name} on the shoulder. They point at a target, then close their eyes without seeing the others. Tap their choice.',
            "Touchez l'épaule de ${p.name}. Il désigne une cible, puis ferme les yeux sans voir les autres. Touchez son choix."),
        selKey: key,
        picker: PickerSpec(
          label: tr('Target of ${p.name}', 'Cible de ${p.name}'),
          tiles: c._tiles(
            selected: c.sel(key).toSet(),
            lock: (q) => q.team != Team.blue,
          ),
          style: PickStyle.red,
        ),
        results: outcome == null
            ? const []
            : [ResultLine(team: Team.red, text: outcome)],
        canContinue: c.sel(key).isNotEmpty,
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    case StepKind.purple:
      final pu = holder(RoleId.purple);
      final out = gone(pu);
      return GuideStep(
        kind: kind,
        kicker: out ? tr('Read it anyway', 'Lisez quand même') : pu!.name,
        title: 'Purple Team',
        team: Team.purple,
        tag: out ? tr('Eliminated', 'Éliminé') : null,
        say: tr('Purple Team, wake up. You may take down one member of the Red Team. Go back to sleep.',
            'Purple Team, réveille-toi. Tu peux éliminer un membre de la Red Team. Rendors-toi.'),
        todo: out
            ? _waitLine
            : tr('${pu!.name} points at a Red Team member, or at nobody. Tap their choice.',
                '${pu!.name} désigne un membre de la Red Team, ou personne. Touchez son choix.'),
        selKey: 'purple',
        picker: out
            ? null
            : PickerSpec(
                label: tr('Eliminate which Red Team member?', 'Éliminer quel membre de la Red Team ?'),
                tiles: c._tiles(
                  selected: c.sel('purple').toSet(),
                  lock: (p) => p.role != RoleId.red,
                ),
                style: PickStyle.red,
                noneLabel: tr('Nobody', 'Personne'),
                noneSelected: c.hasNone('purple'),
              ),
        canContinue: out || c.sel('purple').isNotEmpty || c.hasNone('purple'),
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    case StepKind.responder:
      final ir = holder(RoleId.incidentResponder);
      final out = gone(ir);
      // A blocked attack (Honeypot, C2 disagreement) leaves no victim to show.
      final target = c.effectiveVictim;
      final tName = target == null ? '' : c.players[target].name;
      final zero = ev == EventCard.zeroDay;
      final restoreOk = !c.restoreUsed && target != null && !zero;
      final killOk = !c.killUsed;
      final String say;
      if (target == null) {
        say = tr('Incident Responder, wake up. Nobody was compromised tonight. Do you want to kill a process?',
            "Incident Responder, réveille-toi. Personne n'a été compromis cette nuit. Veux-tu tuer un processus ?");
      } else if (zero) {
        say = tr(
            'Incident Responder, wake up. Tonight, this machine was compromised. Backup Restore is unavailable tonight. Do you want to kill a process?',
            'Incident Responder, réveille-toi. Cette nuit, cette machine a été compromise. Backup Restore est indisponible cette nuit. Veux-tu tuer un processus ?');
      } else {
        say = tr(
            'Incident Responder, wake up. Tonight, this machine was compromised. Do you want to restore a backup? Do you want to kill a process?',
            'Incident Responder, réveille-toi. Cette nuit, cette machine a été compromise. Veux-tu restaurer une sauvegarde ? Veux-tu tuer un processus ?');
      }
      return GuideStep(
        kind: kind,
        kicker: out ? tr('Read it anyway', 'Lisez quand même') : ir!.name,
        title: 'Incident Responder',
        team: Team.blue,
        tag: out ? tr('Eliminated', 'Éliminé') : null,
        say: say,
        todo: out
            ? _waitLine
            : target == null
                ? tr('Nobody was targeted tonight. ${ir!.name} may still use Kill Process by pointing at a player. Tap the tool used.',
                    "Personne n'a été visé cette nuit. ${ir!.name} peut quand même utiliser Kill Process en désignant un joueur. Touchez l'outil utilisé.")
                : tr('Silently point at $tName. ${ir!.name} answers with a thumb for Backup Restore, or points at a player for Kill Process. Tap the tools used.',
                    'Désignez $tName en silence. ${ir!.name} répond avec le pouce pour Backup Restore, ou désigne un joueur pour Kill Process. Touchez les outils utilisés.'),
        tools: out
            ? null
            : ToolsSpec(
                restoreOn: c.restore && restoreOk,
                killOn: c.kill && killOk,
                restoreEnabled: restoreOk,
                killEnabled: killOk,
                restoreSub: c.restoreUsed
                    ? tr('Already used', 'Déjà utilisé')
                    : zero
                        ? tr('Offline tonight', 'Hors ligne cette nuit')
                        : target == null
                            ? tr('Nothing to save', 'Rien à sauver')
                            : tr('Save $tName', 'Sauver $tName'),
                killSub: c.killUsed ? tr('Already used', 'Déjà utilisé') : tr('Take down any machine', "Éliminer n'importe quelle machine"),
              ),
        selKey: 'kill',
        picker: (!out && c.kill && killOk)
            ? PickerSpec(
                label: tr('Kill which machine?', 'Éliminer quelle machine ?'),
                tiles: c._tiles(selected: c.sel('kill').toSet()),
                style: PickStyle.red,
              )
            : null,
        canContinue: out || !(c.kill && killOk) || c.sel('kill').isNotEmpty,
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    case StepKind.dawn:
      return GuideStep(
        kind: kind,
        kicker: tr('Everyone', 'Tout le monde'),
        title: tr('Dawn', "L'aube"),
        say: tr('The night is over. Everyone, open your eyes.', 'La nuit est terminée. Tout le monde, ouvrez les yeux.'),
        todo: tr('The night ambience fades out by itself. Move on to the morning report.',
            "L'ambiance de nuit s'estompe toute seule. Passez au rapport du matin."),
        primaryLabel: tr('Morning report', 'Rapport du matin'),
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    default:
      throw StateError('Not a night step: $kind');
  }
}
