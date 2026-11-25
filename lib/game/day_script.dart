part of 'game_controller.dart';

GuideStep _buildDay(GameController c) {
  if (c.inChain) return _buildChain(c);

  final vis = c._visibleStages();
  final total = vis.length;
  final stepNo = c.dayStage == DayStage.verdict
      ? total
      : max(1, vis.indexOf(c.dayStage) + 1);
  final canBack =
      c.dayStage != DayStage.morning && c.dayStage != DayStage.verdict;
  final bannedNames = c.voteBanned.map((i) => c.players[i].name).toList();
  final banner = bannedNames.isEmpty
      ? null
      : 'Cannot vote today: ${c._join(bannedNames)}';

  switch (c.dayStage) {
    case DayStage.morning:
      final downs = c.entries(c.morningIds);
      final names = c._join(downs.map((d) => d.name).toList());
      final String base;
      if (downs.isEmpty) {
        base = 'Good morning, CORP-LAN. Quiet night: no machine went offline.';
      } else if (downs.length == 1) {
        base =
            'Good morning, CORP-LAN. Overnight, one machine went offline: $names has been compromised. $names, show us your card.';
      } else {
        base =
            'Good morning, CORP-LAN. Overnight, ${downs.length == 2 ? 'two' : 'several'} machines went offline: $names. $names, show us your cards.';
      }
      return GuideStep(
        kind: StepKind.morning,
        kicker: '',
        title: 'Morning report',
        sub:
            '${downs.length} ${downs.length == 1 ? 'machine' : 'machines'} offline',
        say: [base, ...c.morningNotes].join(' '),
        todo: downs.isEmpty
            ? 'Nobody is out. Move on.'
            : 'Each eliminated player reveals their role card and stays silent from now on.',
        report: downs,
        banner: banner,
        canBack: false,
        stepNo: stepNo,
        total: total,
      );

    case DayStage.election:
      return GuideStep(
        kind: StepKind.election,
        kicker: '',
        title: 'CISO election',
        say:
            'Before the debate, the network elects its CISO. Everyone points at one machine. The CISO\'s vote counts double.',
        todo: 'Run a one minute open vote, then tap the elected machine.',
        selKey: 'ciso',
        picker: PickerSpec(
          label: 'Who is the CISO?',
          tiles: c._tiles(selected: {if (c.ciso != null) c.ciso!}),
          style: PickStyle.violet,
        ),
        clock: const ClockSpec(
          id: 'election',
          seconds: 60,
          label: 'Election time left',
        ),
        canContinue: c.ciso != null,
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    case DayStage.event:
      final ev = c.todayEvent;
      final info = ev?.info;
      final forced = c._quizSkipped;
      return GuideStep(
        kind: StepKind.event,
        kicker: 'Expert mode · Event of the day',
        title: info?.title ?? 'Event',
        sub: info?.when ?? '',
        tag: info?.side.label,
        say: info == null
            ? ''
            : forced
                ? 'Event of the day: ${info.title}. ${info.description}'
                : 'Event of the day: ${info.title}. ${info.description} But first, a quiz question: your answers decide if it happens.',
        todo: forced
            ? info?.howTo ?? ''
            : 'Read the name and the description. Then show the quiz question.',
        event: ev,
        banner: banner,
        primaryLabel: forced ? 'Next' : 'Show the question',
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    case DayStage.quiz:
      final ev = c.todayEvent!;
      final spec = _quizSpec(c, ev, revealed: false);
      final mail = spec.email;
      final intro = mail == null
          ? ''
          : 'Everyone received this email. From: ${mail.from}. Subject: ${mail.subject}. "${mail.body}" ';
      return GuideStep(
        kind: StepKind.quiz,
        kicker: 'Quiz · ${ev.info.title}',
        title: 'Quiz question',
        sub: '${spec.alive} players answer',
        tag: ev.info.side.label,
        say:
            '$intro${spec.question} You have one minute to think. No talking.',
        todo:
            'Read the question and the ${spec.answers.length} answers, then press Start. When the timer ends, say: "Three... two... one... show your answer!" Every player still in the game shows ${spec.answers.length == 2 ? '1 or 2' : '1, 2 or 3'} fingers at the same time.',
        quiz: spec,
        clock: ClockSpec(
          id: 'quiz-${c.night}',
          seconds: 60,
          controls: false,
          label: 'Thinking time',
        ),
        banner: banner,
        primaryLabel: 'Reveal the answer',
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    case DayStage.quizAnswer:
      final ev = c.todayEvent!;
      final spec = _quizSpec(c, ev, revealed: true);
      final right = spec.answers[spec.correct];
      final happens = spec.happens;
      return GuideStep(
        kind: StepKind.quizAnswer,
        kicker: 'Quiz · ${ev.info.title}',
        title: 'The answer',
        sub: 'Answer ${spec.correct + 1}',
        tag: ev.info.side.label,
        say: 'The right answer was number ${spec.correct + 1}: $right. ${spec.explanation}',
        todo:
            'Count the players who showed ${spec.correct + 1} finger${spec.correct == 0 ? '' : 's'} and tap that number. More than half means at least ${spec.needed} of ${spec.alive}.',
        quiz: spec,
        banner: banner,
        canContinue: spec.correctCount != null,
        primaryLabel: happens == null
            ? 'Enter the right answers'
            : ev == EventCard.phishing
                ? (spec.majority! ? 'Phishing spotted' : 'Phishing worked')
                : happens
                    ? '${ev.info.title} happens'
                    : '${ev.info.title} is blocked',
        primaryStyle:
            happens == true && ev.info.side == EventSide.red ? PrimaryStyle.red : PrimaryStyle.primary,
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    case DayStage.eventResult:
      final ev = c.todayEvent!;
      final info = ev.info;
      final right = c.quizCorrect ?? 0;
      final alive = c.alivePlayers.length;
      final score = '$right of $alive ${right == 1 ? 'player' : 'players'} found the right answer.';
      final happens = c.eventOutcome == EventOutcome.happens;
      if (ev == EventCard.phishing) {
        final spotted = c.phishSpotted;
        return GuideStep(
          kind: StepKind.eventResult,
          kicker: 'Quiz result',
          title: spotted ? 'Phishing spotted' : 'Phishing worked',
          sub: spotted ? 'Malus for the Red Team' : 'Bonus for the Red Team',
          tag: info.side.label,
          say: spotted
              ? '$score More than half: the phishing campaign was spotted. Malus for the Red Team: their attack fails tonight.'
              : '$score Not enough: the phishing campaign worked. Bonus for the Red Team: tonight they compromise two machines.',
          todo: 'Nothing else to do now: the effect happens tonight. Move on to the debate.',
          banner: banner,
          primaryLabel: 'Next',
          stepNo: stepNo,
          total: total,
          canBack: canBack,
        );
      }
      final (say, sub) = switch (info.side) {
        EventSide.blue => happens
            ? ('$score More than half: the Blue Team gets the advantage. ${info.title} happens. ${info.description}',
                'More than half were right')
            : ('$score Not enough: ${info.title} does not happen.',
                'Not enough right answers'),
        EventSide.red => happens
            ? ('$score Not enough: the company was not ready. ${info.title} happens. ${info.description}',
                'Not enough right answers')
            : ('$score More than half: the company was ready. ${info.title} is blocked.',
                'More than half were right'),
        EventSide.chaos => (
            '$score Chaos Events always happen: ${info.title} happens. ${info.description}',
            'Chaos always happens'
          ),
      };
      final todo = happens
          ? info.howTo
          : 'The Event is blocked: no effect today or tonight. Move on.';
      return GuideStep(
        kind: StepKind.eventResult,
        kicker: 'Quiz result',
        title: happens ? '${info.title} happens' : '${info.title} blocked',
        sub: sub,
        tag: info.side.label,
        say: say,
        todo: todo,
        banner: banner,
        primaryLabel: 'Next',
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    case DayStage.debate:
      if (c.activeEvent == EventCard.ddos && c.ddosOrder.isNotEmpty) {
        final order = c.ddosOrder;
        final i = min(c.ddosIndex, order.length - 1);
        final current = c.players[order[i]].name;
        return GuideStep(
          kind: StepKind.debate,
          kicker: 'DDoS · one at a time',
          title: current,
          sub: 'Speaker ${i + 1} of ${order.length}',
          say: i == 0
              ? 'The network is under attack: no free debate. Each machine speaks once, in turn, for one minute. Nobody can interrupt. $current, you have the floor.'
              : '$current, you have the floor.',
          todo:
              'Starting with the player to the left of the CISO. Tap Next speaker when the minute is over.',
          ddos: DdosSpec(
            current: current,
            index: i,
            total: order.length,
            upcoming: [
              for (final id in order.skip(i + 1).take(3)) c.players[id].name,
            ],
          ),
          clock: ClockSpec(
            id: 'ddos-${c.night}-$i',
            seconds: 60,
            controls: false,
            label: 'Speaking time',
          ),
          banner: banner,
          primaryLabel: i < order.length - 1 ? 'Next speaker' : 'Call the vote',
          stepNo: stepNo,
          total: total,
          canBack: canBack,
        );
      }
      return GuideStep(
        kind: StepKind.debate,
        kicker: c.debateSeconds == 60 ? 'One minute' : 'Three minutes',
        title: 'Debate',
        sub: '${c.alivePlayers.length} machines online',
        say: c.activeEvent == EventCard.maintenanceWindow
            ? 'Incident Review is open. Argue, accuse, defend. Today there will be no quarantine.'
            : 'Incident Review is open. Argue, accuse, defend.',
        todo: 'Let the table talk. Eliminated players stay silent.',
        clock: ClockSpec(
          id: 'debate-${c.night}-${c.debateSeconds}',
          seconds: c.debateSeconds,
          label: 'Debate time left',
        ),
        banner: banner,
        primaryLabel: c.skipVote ? 'End the debate' : 'Call the vote',
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    case DayStage.vote:
      if (c.skipVote) {
        return GuideStep(
          kind: StepKind.vote,
          kicker: 'Maintenance window',
          title: 'No quarantine',
          sub: 'The vote is cancelled',
          say: 'Maintenance window: no quarantine today.',
          todo: 'Skip the vote. The game goes straight to the next Attack Phase.',
          primaryLabel: 'Next attack phase',
          stepNo: stepNo,
          total: total,
          canBack: canBack,
        );
      }
      final cisoP = c.ciso == null ? null : c.players[c.ciso!];
      final pick = c.sel('vote').firstOrNull;
      final none = c.hasNone('vote');
      final silent = c.activeEvent == EventCard.remoteWorkDay;
      final linked = c.link.length == 2 &&
              c.link.every((i) => c.players[i].alive)
          ? ' ${c.players[c.link[0]].name} and ${c.players[c.link[1]].name} share a VPN tunnel: they cannot vote against each other.'
          : '';
      return GuideStep(
        kind: StepKind.vote,
        kicker: 'On the count of three',
        title: 'Quarantine vote',
        sub: cisoP == null ? 'No CISO' : 'CISO: ${cisoP.name}',
        say: silent
            ? 'Remote Work Day: nobody meets at the coffee machine. On my count, everyone points at the machine to quarantine, in silence. Three... two... one... vote!'
            : 'Incident Review is over. On my count, everyone points at the machine to quarantine. Three... two... one... vote!',
        todo:
            'Count the votes and tap the machine with the most. ${cisoP == null ? 'Without a CISO, a tie quarantines nobody.' : '${cisoP.name} votes double and breaks ties.'}$linked',
        banner: banner,
        selKey: 'vote',
        picker: PickerSpec(
          label: 'Machine with the most votes',
          tiles: c._tiles(selected: c.sel('vote').toSet()),
          style: PickStyle.violet,
          noneLabel: cisoP == null ? 'Nobody (tie, no CISO)' : null,
          noneSelected: none,
        ),
        canContinue: pick != null || none,
        primaryLabel: pick != null
            ? 'Quarantine ${c.players[pick].name}'
            : none
                ? 'Nobody is quarantined'
                : 'Pick a machine',
        primaryStyle: PrimaryStyle.red,
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    case DayStage.verdict:
      final downs = c.entries(c.verdictIds);
      final names = c._join(downs.map((d) => d.name).toList());
      return GuideStep(
        kind: StepKind.verdict,
        kicker: 'Result',
        title: 'Quarantine',
        sub: downs.isEmpty ? 'Nobody' : '${downs.length} offline',
        say: downs.isEmpty
            ? 'Nobody is quarantined today.'
            : downs.length == 1
                ? '$names has been quarantined. $names, show us your card.'
                : '$names have gone down. Show us your cards.',
        todo: downs.isEmpty
            ? 'No machine goes down. Move on to the night.'
            : 'Each eliminated player reveals their role card and stays silent from now on.',
        report: downs,
        canBack: false,
        primaryLabel: 'Continue',
        stepNo: stepNo,
        total: total,
      );
  }
}

/// The quiz of today's Event, with the answers in their shuffled order.
QuizSpec _quizSpec(GameController c, EventCard ev, {required bool revealed}) {
  if (ev == EventCard.phishing) {
    final mail = phishEmails[c.phishEmail];
    return QuizSpec(
      question: 'Is this email legitimate or a phishing attempt?',
      answers: const ['Legitimate', 'Phishing'],
      correct: mail.isPhishing ? 1 : 0,
      explanation: mail.explanation,
      side: ev.info.side,
      revealed: revealed,
      alive: c.alivePlayers.length,
      correctCount: c.quizCorrect,
      email: mail,
      majorityRight: 'More than half were right: malus for the Red Team, their attack fails tonight.',
      majorityWrong: 'Not enough right answers: bonus for the Red Team, they compromise 2 machines tonight.',
    );
  }
  final q = ev.quiz;
  final order = c.quizOrder;
  return QuizSpec(
    question: q.question,
    answers: [for (final i in order) q.answers[i]],
    correct: order.indexOf(q.correct),
    explanation: q.explanation,
    side: ev.info.side,
    revealed: revealed,
    alive: c.alivePlayers.length,
    correctCount: c.quizCorrect,
  );
}

/// Dead Man's Switch shots and CISO successors.
GuideStep _buildChain(GameController c) {
  final notice = c.entries(c.noticeIds);

  if (c.pendingDms.isNotEmpty) {
    final p = c.players[c.pendingDms.first];
    final pick = c.sel('dms').firstOrNull;
    final none = c.hasNone('dms');
    return GuideStep(
      kind: StepKind.dms,
      kicker: 'Chain reaction',
      title: 'Dead Man\'s Switch',
      sub: p.name,
      team: Team.blue,
      say:
          '${p.name}, your machine is going down. Take one machine of your choice down with you. Point at it now.',
      todo:
          'Give ${p.name} a few seconds to point at a player. Tap that machine. If time runs out, tap Nobody.',
      selKey: 'dms',
      picker: PickerSpec(
        label: 'Take down which machine?',
        tiles: c._tiles(selected: c.sel('dms').toSet()),
        style: PickStyle.red,
        noneLabel: 'Nobody (time is up)',
        noneSelected: none,
      ),
      clock: ClockSpec(
        id: 'dms-${p.id}',
        seconds: 60,
        controls: false,
        label: 'Time to point',
      ),
      notice: notice,
      canContinue: pick != null || none,
      canBack: false,
      primaryLabel: pick != null
          ? 'Take down ${c.players[pick].name}'
          : none
              ? 'Nobody goes down'
              : 'Pick a machine',
      primaryStyle: PrimaryStyle.red,
      progressLabel: 'Chain reaction',
    );
  }

  final from = c.players[c.pendingCisoFrom!];
  final pick = c.sel('succession').firstOrNull;
  return GuideStep(
    kind: StepKind.succession,
    kicker: 'Chain reaction',
    title: 'CISO successor',
    sub: 'Named by ${from.name}',
    say:
        '${from.name}, you were the CISO and your machine is going down. Name your successor.',
    todo: '${from.name} points at the next CISO. Tap that machine.',
    selKey: 'succession',
    picker: PickerSpec(
      label: 'Who is the new CISO?',
      tiles: c._tiles(selected: c.sel('succession').toSet()),
      style: PickStyle.violet,
    ),
    notice: notice,
    canContinue: pick != null,
    canBack: false,
    primaryLabel: pick != null ? 'Next' : 'Pick the CISO',
    progressLabel: 'Chain reaction',
  );
}
