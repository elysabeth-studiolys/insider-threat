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
      : tr('Cannot vote today: ${c._join(bannedNames)}', "Ne peut pas voter aujourd'hui : ${c._join(bannedNames)}");

  switch (c.dayStage) {
    case DayStage.morning:
      final downs = c.entries(c.morningIds);
      final names = c._join(downs.map((d) => d.name).toList());
      final String base;
      if (downs.isEmpty) {
        base = tr('Good morning, CORP-LAN. Quiet night: no machine went offline.',
            "Bonjour, CORP-LAN. Nuit calme : aucune machine n'est tombée.");
      } else if (downs.length == 1) {
        base = tr(
            'Good morning, CORP-LAN. Overnight, one machine went offline: $names has been compromised. $names, show us your card.',
            'Bonjour, CORP-LAN. Cette nuit, une machine est tombée : $names a été compromis. $names, montre-nous ta carte.');
      } else {
        base = tr(
            "Good morning, CORP-LAN. Overnight, ${downs.length == 2 ? 'two' : 'several'} machines went offline: $names. $names, show us your cards.",
            "Bonjour, CORP-LAN. Cette nuit, ${downs.length == 2 ? 'deux' : 'plusieurs'} machines sont tombées : $names. $names, montrez-nous vos cartes.");
      }
      return GuideStep(
        kind: StepKind.morning,
        kicker: '',
        title: tr('Morning report', 'Rapport du matin'),
        sub: tr("${downs.length} ${downs.length == 1 ? 'machine' : 'machines'} offline",
            "${downs.length} ${downs.length == 1 ? 'machine tombée' : 'machines tombées'}"),
        say: [
          base,
          for (final n in c.morningNotes)
            (switch (n) {
              MorningNote.honeypot => tr('Honeypot triggered: an attack was detected and blocked.',
                  'Honeypot déclenché : une attaque a été détectée et bloquée.'),
              MorningNote.phishSpotted => tr("The phishing campaign was spotted: the Red Team's attack failed.",
                  "La campagne de phishing a été repérée : l'attaque de la Red Team a échoué."),
            }),
        ].join(' '),
        todo: downs.isEmpty
            ? tr('Nobody is out. Move on.', "Personne n'est éliminé. Continuez.")
            : tr('Each eliminated player reveals their role card and stays silent from now on.',
                'Chaque joueur éliminé montre sa carte et se tait à partir de maintenant.'),
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
        title: tr('CISO election', 'Élection du RSSI'),
        say: tr("Before the debate, the network elects its CISO. Everyone points at one machine. The CISO's vote counts double.",
            'Avant le débat, le réseau élit son RSSI. Chacun désigne une machine. La voix du RSSI compte double.'),
        todo: tr('Run a one minute open vote, then tap the elected machine.',
            "Lancez un vote à main levée d'une minute, puis touchez la machine élue."),
        selKey: 'ciso',
        picker: PickerSpec(
          label: tr('Who is the CISO?', 'Qui est le RSSI ?'),
          tiles: c._tiles(selected: {if (c.ciso != null) c.ciso!}),
          style: PickStyle.violet,
        ),
        clock: ClockSpec(
          id: 'election',
          seconds: 60,
          label: tr('Election time left', "Temps restant pour l'élection"),
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
        kicker: tr('Expert mode · Event of the day', 'Mode Expert · Événement du jour'),
        title: info?.title ?? tr('Event', 'Événement'),
        sub: info?.when ?? '',
        tag: info?.side.label,
        say: info == null
            ? ''
            : forced
                ? tr('Event of the day: ${info.title}. ${info.description}',
                    'Événement du jour : ${info.title}. ${info.description}')
                : tr('Event of the day: ${info.title}. ${info.description} But first, a quiz question: your answers decide if it happens.',
                    "Événement du jour : ${info.title}. ${info.description} Mais d'abord, une question de quiz : vos réponses décident s'il a lieu."),
        todo: forced
            ? info?.howTo ?? ''
            : tr('Read the name and the description. Then show the quiz question.',
                'Lisez le nom et la description. Puis affichez la question du quiz.'),
        event: ev,
        banner: banner,
        primaryLabel: forced ? tr('Next', 'Suivant') : tr('Show the question', 'Afficher la question'),
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
          : tr('Everyone received this email. From: ${mail.from}. Subject: ${mail.subject}. "${mail.body}" ',
              'Tout le monde a reçu cet e-mail. De : ${mail.from}. Objet : ${mail.subject}. « ${mail.body} » ');
      return GuideStep(
        kind: StepKind.quiz,
        kicker: 'Quiz · ${ev.info.title}',
        title: tr('Quiz question', 'Question du quiz'),
        sub: tr('${spec.alive} players answer', '${spec.alive} joueurs répondent'),
        tag: ev.info.side.label,
        say: intro +
            tr('${spec.question} You have one minute to think. No talking.',
                '${spec.question} Vous avez une minute pour réfléchir. Sans parler.'),
        todo: tr(
            "Read the question and the ${spec.answers.length} answers, then press Start. When the timer ends, say: \"Three... two... one... show your answer!\" Every player still in the game shows ${spec.answers.length == 2 ? '1 or 2' : '1, 2 or 3'} fingers at the same time.",
            "Lisez la question et les ${spec.answers.length} réponses, puis appuyez sur Démarrer. À la fin du chrono, dites : « Trois… deux… un… montrez votre réponse ! » Chaque joueur encore en jeu montre ${spec.answers.length == 2 ? '1 ou 2' : '1, 2 ou 3'} doigts en même temps."),
        quiz: spec,
        clock: ClockSpec(
          id: 'quiz-${c.night}',
          seconds: 60,
          controls: false,
          label: tr('Thinking time', 'Temps de réflexion'),
        ),
        banner: banner,
        primaryLabel: tr('Reveal the answer', 'Révéler la réponse'),
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
        title: tr('The answer', 'La réponse'),
        sub: tr('Answer ${spec.correct + 1}', 'Réponse ${spec.correct + 1}'),
        tag: ev.info.side.label,
        say: tr('The right answer was number ${spec.correct + 1}: $right. ${spec.explanation}',
            'La bonne réponse était la numéro ${spec.correct + 1} : $right. ${spec.explanation}'),
        todo: tr(
            "Count the players who showed ${spec.correct + 1} finger${spec.correct == 0 ? '' : 's'} and tap that number. More than half means at least ${spec.needed} of ${spec.alive}.",
            "Comptez les joueurs qui ont montré ${spec.correct + 1} doigt${spec.correct == 0 ? '' : 's'} et touchez ce nombre. Plus de la moitié, c'est au moins ${spec.needed} sur ${spec.alive}."),
        quiz: spec,
        banner: banner,
        canContinue: spec.correctCount != null,
        primaryLabel: happens == null
            ? tr('Enter the right answers', 'Saisir les bonnes réponses')
            : ev == EventCard.phishing
                ? (spec.majority! ? tr('Phishing spotted', 'Phishing repéré') : tr('Phishing worked', 'Le phishing a marché'))
                : happens
                    ? tr('${ev.info.title} happens', '${ev.info.title} a lieu')
                    : tr('${ev.info.title} is blocked', '${ev.info.title} est bloqué'),
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
      final score = tr("$right of $alive ${right == 1 ? 'player' : 'players'} found the right answer.",
          "$right joueur${right > 1 ? 's' : ''} sur $alive ${right > 1 ? 'ont' : 'a'} trouvé la bonne réponse.");
      final happens = c.eventOutcome == EventOutcome.happens;
      if (ev == EventCard.phishing) {
        final spotted = c.phishSpotted;
        return GuideStep(
          kind: StepKind.eventResult,
          kicker: tr('Quiz result', 'Résultat du quiz'),
          title: spotted ? tr('Phishing spotted', 'Phishing repéré') : tr('Phishing worked', 'Le phishing a marché'),
          sub: spotted ? tr('Malus for the Red Team', 'Malus pour la Red Team') : tr('Bonus for the Red Team', 'Bonus pour la Red Team'),
          tag: info.side.label,
          say: spotted
              ? tr('$score More than half: the phishing campaign was spotted. Malus for the Red Team: their attack fails tonight.',
                  '$score Plus de la moitié : la campagne de phishing a été repérée. Malus pour la Red Team : son attaque échoue cette nuit.')
              : tr('$score Not enough: the phishing campaign worked. Bonus for the Red Team: tonight they compromise two machines.',
                  '$score Pas assez : la campagne de phishing a marché. Bonus pour la Red Team : cette nuit, elle compromet deux machines.'),
          todo: tr('Nothing else to do now: the effect happens tonight. Move on to the debate.',
              "Rien d'autre à faire pour l'instant : l'effet a lieu cette nuit. Passez au débat."),
          banner: banner,
          primaryLabel: tr('Next', 'Suivant'),
          stepNo: stepNo,
          total: total,
          canBack: canBack,
        );
      }
      final (say, sub) = switch (info.side) {
        EventSide.blue => happens
            ? (tr('$score More than half: the Blue Team gets the advantage. ${info.title} happens. ${info.description}',
                    "$score Plus de la moitié : la Blue Team prend l'avantage. ${info.title} a lieu. ${info.description}"),
                tr('More than half were right', 'Plus de la moitié ont eu juste'))
            : (tr('$score Not enough: ${info.title} does not happen.', "$score Pas assez : ${info.title} n'a pas lieu."),
                tr('Not enough right answers', 'Pas assez de bonnes réponses')),
        EventSide.red => happens
            ? (tr('$score Not enough: the company was not ready. ${info.title} happens. ${info.description}',
                    "$score Pas assez : l'entreprise n'était pas prête. ${info.title} a lieu. ${info.description}"),
                tr('Not enough right answers', 'Pas assez de bonnes réponses'))
            : (tr('$score More than half: the company was ready. ${info.title} is blocked.',
                    "$score Plus de la moitié : l'entreprise était prête. ${info.title} est bloqué."),
                tr('More than half were right', 'Plus de la moitié ont eu juste')),
        EventSide.chaos => (
            tr('$score Chaos Events always happen: ${info.title} happens. ${info.description}',
                '$score Les Events Chaos ont toujours lieu : ${info.title} a lieu. ${info.description}'),
            tr('Chaos always happens', 'Le Chaos a toujours lieu')
          ),
      };
      final todo = happens
          ? info.howTo
          : tr('The Event is blocked: no effect today or tonight. Move on.',
              "L'Event est bloqué : aucun effet aujourd'hui ni cette nuit. Continuez.");
      return GuideStep(
        kind: StepKind.eventResult,
        kicker: tr('Quiz result', 'Résultat du quiz'),
        title: happens ? tr('${info.title} happens', '${info.title} a lieu') : tr('${info.title} blocked', '${info.title} bloqué'),
        sub: sub,
        tag: info.side.label,
        say: say,
        todo: todo,
        banner: banner,
        primaryLabel: tr('Next', 'Suivant'),
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
          kicker: tr('DDoS · one at a time', 'DDoS · un à la fois'),
          title: current,
          sub: tr('Speaker ${i + 1} of ${order.length}', 'Orateur ${i + 1} sur ${order.length}'),
          say: i == 0
              ? tr('The network is under attack: no free debate. Each machine speaks once, in turn, for one minute. Nobody can interrupt. $current, you have the floor.',
                  'Le réseau est attaqué : pas de débat libre. Chaque machine parle une fois, à tour de rôle, pendant une minute. Personne ne peut interrompre. $current, tu as la parole.')
              : tr('$current, you have the floor.', '$current, tu as la parole.'),
          todo: tr('Starting with the player to the left of the CISO. Tap Next speaker when the minute is over.',
              'En commençant par le joueur à gauche du RSSI. Touchez Orateur suivant quand la minute est écoulée.'),
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
            label: tr('Speaking time', 'Temps de parole'),
          ),
          banner: banner,
          primaryLabel: i < order.length - 1 ? tr('Next speaker', 'Orateur suivant') : tr('Call the vote', 'Passer au vote'),
          stepNo: stepNo,
          total: total,
          canBack: canBack,
        );
      }
      return GuideStep(
        kind: StepKind.debate,
        kicker: c.debateSeconds == 60 ? tr('One minute', 'Une minute') : tr('Three minutes', 'Trois minutes'),
        title: tr('Debate', 'Débat'),
        sub: tr('${c.alivePlayers.length} machines online', '${c.alivePlayers.length} machines en ligne'),
        say: c.activeEvent == EventCard.maintenanceWindow
            ? tr('Incident Review is open. Argue, accuse, defend. Today there will be no quarantine.',
                "L'Incident Review est ouverte. Argumentez, accusez, défendez-vous. Aujourd'hui, il n'y aura pas de quarantaine.")
            : tr('Incident Review is open. Argue, accuse, defend.', "L'Incident Review est ouverte. Argumentez, accusez, défendez-vous."),
        todo: tr('Let the table talk. Eliminated players stay silent.', 'Laissez la table parler. Les joueurs éliminés se taisent.'),
        clock: ClockSpec(
          id: 'debate-${c.night}-${c.debateSeconds}',
          seconds: c.debateSeconds,
          label: tr('Debate time left', 'Temps de débat restant'),
        ),
        banner: banner,
        primaryLabel: c.skipVote ? tr('End the debate', 'Terminer le débat') : tr('Call the vote', 'Passer au vote'),
        stepNo: stepNo,
        total: total,
        canBack: canBack,
      );

    case DayStage.vote:
      if (c.skipVote) {
        return GuideStep(
          kind: StepKind.vote,
          kicker: 'Maintenance Window',
          title: tr('No quarantine', 'Pas de quarantaine'),
          sub: tr('The vote is cancelled', 'Le vote est annulé'),
          say: tr('Maintenance window: no quarantine today.', "Maintenance Window : pas de quarantaine aujourd'hui."),
          todo: tr('Skip the vote. The game goes straight to the next Attack Phase.',
              "Pas de vote. La partie passe directement à la prochaine Attack Phase."),
          primaryLabel: tr('Next attack phase', 'Attack Phase suivante'),
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
          ? tr(' ${c.players[c.link[0]].name} and ${c.players[c.link[1]].name} share a VPN tunnel: they cannot vote against each other.',
              " ${c.players[c.link[0]].name} et ${c.players[c.link[1]].name} partagent un tunnel VPN : ils ne peuvent pas voter l'un contre l'autre.")
          : '';
      return GuideStep(
        kind: StepKind.vote,
        kicker: tr('On the count of three', 'À trois'),
        title: tr('Quarantine vote', 'Vote de quarantaine'),
        sub: cisoP == null ? tr('No CISO', 'Pas de RSSI') : tr('CISO: ${cisoP.name}', 'RSSI : ${cisoP.name}'),
        say: silent
            ? tr('Remote Work Day: nobody meets at the coffee machine. On my count, everyone points at the machine to quarantine, in silence. Three... two... one... vote!',
                'Remote Work Day : personne ne se croise à la machine à café. À mon signal, chacun désigne en silence la machine à mettre en quarantaine. Trois… deux… un… votez !')
            : tr('Incident Review is over. On my count, everyone points at the machine to quarantine. Three... two... one... vote!',
                "L'Incident Review est terminée. À mon signal, chacun désigne la machine à mettre en quarantaine. Trois… deux… un… votez !"),
        todo: tr('Count the votes and tap the machine with the most. ', 'Comptez les voix et touchez la machine qui en a le plus. ') +
            (cisoP == null
                ? tr('Without a CISO, a tie quarantines nobody.', "Sans RSSI, une égalité ne met personne en quarantaine.")
                : tr('${cisoP.name} votes double and breaks ties.', '${cisoP.name} vote double et départage les égalités.')) +
            linked,
        banner: banner,
        selKey: 'vote',
        picker: PickerSpec(
          label: tr('Machine with the most votes', 'Machine avec le plus de voix'),
          tiles: c._tiles(selected: c.sel('vote').toSet()),
          style: PickStyle.violet,
          noneLabel: cisoP == null ? tr('Nobody (tie, no CISO)', 'Personne (égalité, pas de RSSI)') : null,
          noneSelected: none,
        ),
        canContinue: pick != null || none,
        primaryLabel: pick != null
            ? tr('Quarantine ${c.players[pick].name}', 'Mettre ${c.players[pick].name} en quarantaine')
            : none
                ? tr('Nobody is quarantined', 'Personne en quarantaine')
                : tr('Pick a machine', 'Choisissez une machine'),
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
        kicker: tr('Result', 'Résultat'),
        title: tr('Quarantine', 'Quarantaine'),
        sub: downs.isEmpty ? tr('Nobody', 'Personne') : tr('${downs.length} offline', '${downs.length} hors ligne'),
        say: downs.isEmpty
            ? tr('Nobody is quarantined today.', "Personne n'est mis en quarantaine aujourd'hui.")
            : downs.length == 1
                ? tr('$names has been quarantined. $names, show us your card.', '$names a été mis en quarantaine. $names, montre-nous ta carte.')
                : tr('$names have gone down. Show us your cards.', '$names sont tombés. Montrez-nous vos cartes.'),
        todo: downs.isEmpty
            ? tr('No machine goes down. Move on to the night.', 'Aucune machine ne tombe. Passez à la nuit.')
            : tr('Each eliminated player reveals their role card and stays silent from now on.',
                'Chaque joueur éliminé montre sa carte et se tait à partir de maintenant.'),
        report: downs,
        canBack: false,
        primaryLabel: tr('Continue', 'Continuer'),
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
      question: tr('Is this email legitimate or a phishing attempt?', 'Cet e-mail est-il légitime ou une tentative de phishing ?'),
      answers: [tr('Legitimate', 'Légitime'), 'Phishing'],
      correct: mail.isPhishing ? 1 : 0,
      explanation: mail.explanation,
      side: ev.info.side,
      revealed: revealed,
      alive: c.alivePlayers.length,
      correctCount: c.quizCorrect,
      email: mail,
      majorityRight: tr('More than half were right: malus for the Red Team, their attack fails tonight.',
          'Plus de la moitié ont eu juste : malus pour la Red Team, son attaque échoue cette nuit.'),
      majorityWrong: tr('Not enough right answers: bonus for the Red Team, they compromise 2 machines tonight.',
          'Pas assez de bonnes réponses : bonus pour la Red Team, elle compromet 2 machines cette nuit.'),
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
      kicker: tr('Chain reaction', 'Réaction en chaîne'),
      title: "Dead Man's Switch",
      sub: p.name,
      team: Team.blue,
      say: tr('${p.name}, your machine is going down. Take one machine of your choice down with you. Point at it now.',
          '${p.name}, ta machine tombe. Emporte avec toi une machine de ton choix. Désigne-la maintenant.'),
      todo: tr('Give ${p.name} a few seconds to point at a player. Tap that machine. If time runs out, tap Nobody.',
          'Laissez à ${p.name} quelques secondes pour désigner un joueur. Touchez cette machine. Si le temps est écoulé, touchez Personne.'),
      selKey: 'dms',
      picker: PickerSpec(
        label: tr('Take down which machine?', 'Emporter quelle machine ?'),
        tiles: c._tiles(selected: c.sel('dms').toSet()),
        style: PickStyle.red,
        noneLabel: tr('Nobody (time is up)', 'Personne (temps écoulé)'),
        noneSelected: none,
      ),
      clock: ClockSpec(
        id: 'dms-${p.id}',
        seconds: 60,
        controls: false,
        label: tr('Time to point', 'Temps pour désigner'),
      ),
      notice: notice,
      canContinue: pick != null || none,
      canBack: false,
      primaryLabel: pick != null
          ? tr('Take down ${c.players[pick].name}', 'Emporter ${c.players[pick].name}')
          : none
              ? tr('Nobody goes down', 'Personne ne tombe')
              : tr('Pick a machine', 'Choisissez une machine'),
      primaryStyle: PrimaryStyle.red,
      progressLabel: tr('Chain reaction', 'Réaction en chaîne'),
    );
  }

  final from = c.players[c.pendingCisoFrom!];
  final pick = c.sel('succession').firstOrNull;
  return GuideStep(
    kind: StepKind.succession,
    kicker: tr('Chain reaction', 'Réaction en chaîne'),
    title: tr('CISO successor', 'Successeur du RSSI'),
    sub: tr('Named by ${from.name}', 'Nommé par ${from.name}'),
    say: tr('${from.name}, you were the CISO and your machine is going down. Name your successor.',
        '${from.name}, tu étais le RSSI et ta machine tombe. Nomme ton successeur.'),
    todo: tr('${from.name} points at the next CISO. Tap that machine.', '${from.name} désigne le prochain RSSI. Touchez cette machine.'),
    selKey: 'succession',
    picker: PickerSpec(
      label: tr('Who is the new CISO?', 'Qui est le nouveau RSSI ?'),
      tiles: c._tiles(selected: c.sel('succession').toSet()),
      style: PickStyle.violet,
    ),
    notice: notice,
    canContinue: pick != null,
    canBack: false,
    primaryLabel: pick != null ? tr('Next', 'Suivant') : tr('Pick the CISO', 'Choisissez le RSSI'),
    progressLabel: tr('Chain reaction', 'Réaction en chaîne'),
  );
}
