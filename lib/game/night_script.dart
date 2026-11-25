part of 'game_controller.dart';

const _waitLine =
    'Nobody can use this power. Read the line anyway and wait a few seconds.';

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
        kicker: 'Everyone',
        title: 'Nightfall',
        tag: ev == null ? null : 'Event: ${ev.info.title}',
        say: 'Night falls on CORP-LAN. All employees, log off and close your eyes.'
            '${ev == EventCard.powerOutage ? ' Power outage: all special powers are offline tonight.' : ''}'
            '${ev == EventCard.phishing ? (c.phishSpotted ? ' The phishing campaign was spotted: the Red Team will not attack tonight.' : ' The phishing campaign worked: tonight the Red Team strikes twice.') : ''}',
        todo:
            'The night ambience starts by itself. Wait until the table is silent. Players never speak at night: they point.',
        secret: hp == null
            ? null
            : 'Honeypot decoy: ${c.players[hp].name}. If the Red Team targets this machine tonight, the attack fails. Tell nobody.',
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    case StepKind.engineer:
      final ne = holder(RoleId.networkEngineer);
      final out = gone(ne);
      return GuideStep(
        kind: kind,
        kicker: out ? 'Read it anyway' : ne!.name,
        title: 'Network Engineer',
        team: Team.blue,
        tag: out ? 'Eliminated' : null,
        say:
            'Network Engineer, wake up. Point at two machines to link with a VPN tunnel. Network Engineer, go back to sleep.',
        todo: out
            ? _waitLine
            : '${ne!.name} points at two machines (they may include themselves). Tap both.',
        selKey: 'link',
        picker: out
            ? null
            : PickerSpec(
                label: 'Pick two machines (${c.link.length}/2)',
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
        kicker: linked ? '${a!.name} and ${b!.name}' : 'Nobody linked',
        title: 'Linked machines',
        team: Team.purple,
        say:
            'I will tap the two linked machines. Linked machines, open your eyes and recognise each other. If one of you goes down, the other goes down too. Close your eyes.',
        todo: linked
            ? 'Tap ${a!.name} and ${b!.name} on the shoulder. Let them see each other, then ask them to close their eyes.'
            : 'Nobody is linked. Read the line anyway and wait a few seconds.',
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
        kicker: out ? 'Read it anyway' : th!.name,
        title: 'Threat Hunter',
        team: Team.blue,
        tag: out ? 'Eliminated' : null,
        say: need == 2
            ? 'Threat Hunter, wake up. Tonight, you may inspect two machines. Point at the machines you want to inspect. Threat Hunter, go back to sleep.'
            : 'Threat Hunter, wake up. Point at the machine you want to inspect. Threat Hunter, go back to sleep.',
        todo: out
            ? _waitLine
            : need == 2
                ? '${th!.name} points at two players. Tap both: the cards appear on screen. Silently turn the phone towards ${th.name}, one card after the other.'
                : '${th!.name} points at a player. Tap that player: the card appears on screen. Silently turn the phone towards ${th.name}.',
        selKey: 'hunter',
        picker: out
            ? null
            : PickerSpec(
                label: need == 2 ? 'Which machines? (${picks.length}/2)' : 'Which machine?',
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
                    text:
                        'Show ${th!.name} the role card of ${c.players[id].name}: ${c.players[id].role.info.name} (${c.players[id].role.info.character})',
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
            ? 'Red Team, wake up. Look at each other. With the stolen credentials, silently choose two machines to compromise. Red Team, go back to sleep.'
            : 'Red Team, wake up. Look at each other. Silently choose one machine to compromise. Red Team, go back to sleep.',
        todo: twice
            ? 'They point at two players and you nod to confirm. Tap both. The first one is tonight\'s victim for the Incident Responder; the second cannot be restored. The SOC Analyst may peek.'
            : 'They point at a player and you nod to confirm. Tap the victim. ${ev == EventCard.powerOutage ? 'Power outage: the SOC Analyst cannot peek.' : 'The SOC Analyst may peek.'}',
        selKey: 'red',
        picker: PickerSpec(
          label: twice ? 'Tap the two victims (${c.sel('red').length}/2)' : 'Tap the victim',
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
            ? 'No agreement: the attack fails. Tonight is a quiet night.'
            : 'The attackers agree on ${c.players[t].name}.';
      }
      return GuideStep(
        kind: kind,
        kicker: 'C2 server down · attacker ${idx + 1} of ${attackers.length}',
        title: p.name,
        team: p.team,
        sub: p.role.info.name,
        say: idx == 0
            ? 'The attackers\' C2 server is down. The attacker I tap, open your eyes and point at your target. Close your eyes.'
            : 'Next attacker, open your eyes and point at your target. Close your eyes.',
        todo:
            'Tap ${p.name} on the shoulder. They point at a target, then close their eyes without seeing the others. Tap their choice.',
        selKey: key,
        picker: PickerSpec(
          label: 'Target of ${p.name}',
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
        kicker: out ? 'Read it anyway' : pu!.name,
        title: 'Purple Team',
        team: Team.purple,
        tag: out ? 'Eliminated' : null,
        say:
            'Purple Team, wake up. You may take down one member of the Red Team. Go back to sleep.',
        todo: out
            ? _waitLine
            : '${pu!.name} points at a Red Team member, or at nobody. Tap their choice.',
        selKey: 'purple',
        picker: out
            ? null
            : PickerSpec(
                label: 'Eliminate which Red Team member?',
                tiles: c._tiles(
                  selected: c.sel('purple').toSet(),
                  lock: (p) => p.role != RoleId.red,
                ),
                style: PickStyle.red,
                noneLabel: 'Nobody',
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
        say =
            'Incident Responder, wake up. Nobody was compromised tonight. Do you want to kill a process?';
      } else if (zero) {
        say =
            'Incident Responder, wake up. Tonight, this machine was compromised. Backup Restore is unavailable tonight. Do you want to kill a process?';
      } else {
        say =
            'Incident Responder, wake up. Tonight, this machine was compromised. Do you want to restore a backup? Do you want to kill a process?';
      }
      return GuideStep(
        kind: kind,
        kicker: out ? 'Read it anyway' : ir!.name,
        title: 'Incident Responder',
        team: Team.blue,
        tag: out ? 'Eliminated' : null,
        say: say,
        todo: out
            ? _waitLine
            : target == null
                ? 'Nobody was targeted tonight. ${ir!.name} may still use Kill Process by pointing at a player. Tap the tool used.'
                : 'Silently point at $tName. ${ir!.name} answers with a thumb for Backup Restore, or points at a player for Kill Process. Tap the tools used.',
        tools: out
            ? null
            : ToolsSpec(
                restoreOn: c.restore && restoreOk,
                killOn: c.kill && killOk,
                restoreEnabled: restoreOk,
                killEnabled: killOk,
                restoreSub: c.restoreUsed
                    ? 'Already used'
                    : zero
                        ? 'Offline tonight'
                        : target == null
                            ? 'Nothing to save'
                            : 'Save $tName',
                killSub: c.killUsed ? 'Already used' : 'Take down any machine',
              ),
        selKey: 'kill',
        picker: (!out && c.kill && killOk)
            ? PickerSpec(
                label: 'Kill which machine?',
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
        kicker: 'Everyone',
        title: 'Dawn',
        say: 'The night is over. Everyone, open your eyes.',
        todo: 'The night ambience fades out by itself. Move on to the morning report.',
        primaryLabel: 'Morning report',
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    default:
      throw StateError('Not a night step: $kind');
  }
}
