/// The rules engine and narration state machine.
///
/// A game alternates night and day. The controller owns every piece of state
/// (who is alive, VPN link, CISO, tools used, event effects) and exposes the
/// current [GuideStep], which is all the UI needs to render.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import 'events.dart';
import 'guide_step.dart';
import 'models.dart';
import '../i18n.dart';

part 'day_script.dart';
part 'night_script.dart';

enum GamePhase { night, day, end }

/// Order matters: stages are visited in this order.
enum DayStage {
  morning,
  election,
  event,
  quiz,
  quizAnswer,
  eventResult,
  debate,
  vote,
  verdict,
}

/// What the quiz decided for today's Event.
enum EventOutcome { pending, happens, blocked }

/// Extra facts announced in the morning report.
enum MorningNote { honeypot, phishSpotted }

class GameController extends ChangeNotifier {
  GameController({
    required List<Player> players,
    required this.expert,
    Random? random,
  })  : players = List.unmodifiable(players),
        rng = random ?? Random(),
        inPlay = players.map((p) => p.role).toSet() {
    _beginNight(first: true);
  }

  final List<Player> players;
  final bool expert;
  final Random rng;

  /// Roles dealt at the start. Only these are called at night, even when
  /// their holder is gone, so that silence never reveals who is out.
  final Set<RoleId> inPlay;

  GamePhase phase = GamePhase.night;
  Winner? winner;
  int night = 1;
  int nightCursor = 0;
  DayStage dayStage = DayStage.morning;

  /// True while Dead Man's Switch / CISO successor steps are being resolved.
  bool inChain = false;

  // --- persistent game state -------------------------------------------------
  List<int> link = [];
  int? ciso;
  bool restoreUsed = false;
  bool killUsed = false;

  // --- night inputs ------------------------------------------------------------
  final Map<String, List<int>> _sel = {};
  final Set<String> _none = {};
  bool restore = false;
  bool kill = false;
  EventCard? nightEvent;
  int? honeypotId;

  /// Phishing Campaign: did the majority judge the email correctly? Decided
  /// by the day quiz, used tonight: true = malus for the Red Team (attack
  /// fails), false = bonus (two victims).
  bool phishSpotted = false;

  /// Phishing Campaign: index of today's email in [phishEmails].
  int phishEmail = 0;

  // --- day state ---------------------------------------------------------------
  /// The Event drawn today. It only takes effect once the quiz says so: see
  /// [eventOutcome] and [activeEvent].
  EventCard? todayEvent;
  EventOutcome eventOutcome = EventOutcome.pending;

  /// Right answers entered by the Narrator after the quiz.
  int? quizCorrect;

  /// Order in which the quiz answers are shown (indexes into the answers).
  List<int> quizOrder = const [0, 1, 2];

  /// Set by tests that force an Event: no quiz steps for that day.
  bool _quizSkipped = false;
  List<int> morningIds = [];
  /// Extra lines of the morning report, turned into text when shown (so they
  /// follow the language even if it changes mid-game).
  List<MorningNote> morningNotes = [];
  List<int> verdictIds = [];
  List<int> noticeIds = [];
  Set<int> voteBanned = {};
  bool electionToday = false;
  bool skipDebate = false;
  bool skipVote = false;
  /// Debate length (rules: 3 minutes, Black Friday Rush: 1 minute).
  int debateSeconds = 180;
  List<int> ddosOrder = [];
  int ddosIndex = 0;

  final List<int> pendingDms = [];
  int? pendingCisoFrom;
  bool _thenNight = false;
  final List<EventCard> _deck = [];

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  List<Player> get alivePlayers => players.where((p) => p.alive).toList();

  Player? holder(RoleId r) {
    for (final p in players) {
      if (p.role == r) return p;
    }
    return null;
  }

  List<int> sel(String key) => _sel[key] ?? const [];
  bool hasNone(String key) => _none.contains(key);

  /// Today's Event, only if the quiz let it happen.
  EventCard? get activeEvent =>
      eventOutcome == EventOutcome.happens ? todayEvent : null;

  List<DownEntry> entries(Iterable<int> ids) => ids
      .map((i) => players[i])
      .map((p) => DownEntry(
            name: p.name,
            role: p.role.info.name,
            team: p.team,
          ))
      .toList();

  GuideStep get currentStep {
    assert(phase != GamePhase.end, 'No step once the game is over');
    return phase == GamePhase.night ? _buildNight(this) : _buildDay(this);
  }

  /// The machine the Red Team (or the attackers, one by one) aimed at tonight.
  int? get rawTarget {
    if (nightEvent == EventCard.c2ServerDown) {
      final attackers = _attackersOf(this);
      if (attackers.isEmpty) return null;
      // The target goes down only if every attacker chose it.
      final targets = {
        for (final a in attackers) _sel['red:${a.id}']?.firstOrNull,
      };
      return targets.length == 1 ? targets.single : null;
    }
    return _sel['red']?.firstOrNull;
  }

  bool get honeypotTriggered =>
      nightEvent == EventCard.honeypot &&
      rawTarget != null &&
      rawTarget == honeypotId;

  /// The machine that will really be compromised (before tools).
  int? get effectiveVictim => honeypotTriggered ? null : rawTarget;

  /// Win conditions, checked after every elimination.
  Winner? checkWinner() {
    final alive = alivePlayers;
    if (alive.isEmpty) return Winner.outage;
    if (link.length == 2 && alive.length == 2) {
      final ids = alive.map((p) => p.id).toSet();
      if (ids.containsAll(link) &&
          players[link[0]].team != players[link[1]].team) {
        return Winner.vpn;
      }
    }
    final reds = alive.where((p) => p.team == Team.red).length;
    final purples = alive.where((p) => p.team == Team.purple).length;
    final blues = alive.length - reds - purples;
    if (reds == 0 && purples == 0) return Winner.blue;
    if (blues == 0 && purples == 0) return Winner.red;
    if (blues == 0 && reds == 0) return Winner.purple;
    return null;
  }

  // ---------------------------------------------------------------------------
  // Actions (called by the UI)
  // ---------------------------------------------------------------------------

  void pick(int id) {
    if (phase == GamePhase.end) return;
    final step = currentStep;
    final key = step.selKey;
    final picker = step.picker;
    if (key == null || picker == null) return;
    final tile = picker.tiles.firstWhere((t) => t.id == id);
    if (tile.locked) return;

    switch (step.kind) {
      case StepKind.engineer:
        if (link.contains(id)) {
          link = link.where((x) => x != id).toList();
        } else {
          link = [...link, id];
          if (link.length > 2) link = link.sublist(link.length - 2);
        }
      case StepKind.election:
        ciso = id;
      default:
        final list = List<int>.of(_sel[key] ?? const []);
        if (list.contains(id)) {
          list.remove(id);
        } else if (picker.max == 1) {
          list
            ..clear()
            ..add(id);
        } else {
          list.add(id);
          if (list.length > picker.max) list.removeAt(0);
        }
        _sel[key] = list;
        _none.remove(key);
    }
    notifyListeners();
  }

  void pickNone() {
    final key = currentStep.selKey;
    if (key == null) return;
    _sel.remove(key);
    _none.add(key);
    notifyListeners();
  }

  void toggleRestore() {
    final tools = currentStep.tools;
    if (tools == null || !tools.restoreEnabled) return;
    restore = !restore;
    notifyListeners();
  }

  void toggleKill() {
    final tools = currentStep.tools;
    if (tools == null || !tools.killEnabled) return;
    kill = !kill;
    if (!kill) _sel.remove('kill');
    notifyListeners();
  }

  /// Number of players who found the right quiz answer.
  void setQuizCorrect(int n) {
    if (phase != GamePhase.day || dayStage != DayStage.quizAnswer) return;
    quizCorrect = n.clamp(0, alivePlayers.length).toInt();
    notifyListeners();
  }

  void primary() {
    switch (phase) {
      case GamePhase.end:
        return;
      case GamePhase.night:
        if (!currentStep.canContinue) return;
        if (nightCursor < _nightPlan(this).length - 1) {
          nightCursor++;
        } else {
          _resolveNight();
        }
      case GamePhase.day:
        if (!currentStep.canContinue) return;
        if (inChain) {
          _confirmChain();
        } else {
          _dayPrimary();
        }
    }
    notifyListeners();
  }

  void back() {
    if (phase == GamePhase.night) {
      if (nightCursor > 0) nightCursor--;
    } else if (phase == GamePhase.day &&
        !inChain &&
        dayStage != DayStage.morning &&
        dayStage != DayStage.verdict) {
      final vis = _visibleStages();
      final i = vis.indexOf(dayStage);
      if (i > 0) dayStage = vis[i - 1];
    }
    notifyListeners();
  }

  /// The day whose Event card has already been revealed with its animation.
  int eventRevealedNight = 0;

  bool get eventRevealed => todayEvent != null && eventRevealedNight == night;

  /// Called once the draw animation is over, so it does not replay when the
  /// Narrator goes back to the Event step.
  void markEventRevealed() {
    if (eventRevealed) return;
    eventRevealedNight = night;
    notifyListeners();
  }

  /// Replaces today's drawn Event; the quiz still decides if it happens.
  @visibleForTesting
  void debugDrawEvent(EventCard card) {
    _setDrawn(card);
    notifyListeners();
  }

  /// Forces today's Event and applies it right away, without a quiz.
  @visibleForTesting
  void debugSetTodayEvent(EventCard card) {
    todayEvent = card;
    eventOutcome = EventOutcome.happens;
    _quizSkipped = true;
    _resetEventEffects();
    _applyEffects(card);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Night
  // ---------------------------------------------------------------------------

  void _beginNight({bool first = false}) {
    if (!first) night++;
    phase = GamePhase.night;
    nightCursor = 0;
    _sel.clear();
    _none.clear();
    restore = false;
    kill = false;
    voteBanned = {};
    inChain = false;

    // A blocked Event has no effect tonight either.
    nightEvent = activeEvent;
    todayEvent = null;
    _clearQuiz();
    honeypotId = null;
    if (nightEvent == EventCard.honeypot) {
      final candidates = alivePlayers.where((p) => p.team == Team.blue);
      if (candidates.isNotEmpty) {
        honeypotId = candidates.elementAt(rng.nextInt(candidates.length)).id;
      }
    }
  }

  void _resolveNight() {
    final ev = nightEvent;
    final outage = ev == EventCard.powerOutage;
    final deaths = <int>[];
    final notes = <MorningNote>[];

    // The Incident Responder's tools only count when they could really be used.
    final ir = holder(RoleId.incidentResponder);
    final irActive = ir != null && ir.alive && !outage;
    // A blocked attack (Honeypot) leaves nothing to restore.
    final victim = effectiveVictim;
    final useRestore = restore &&
        irActive &&
        !restoreUsed &&
        victim != null &&
        ev != EventCard.zeroDay;
    final useKill = kill && irActive && !killUsed;

    if (useRestore) restoreUsed = true;
    if (victim != null && !useRestore) deaths.add(victim);
    if (honeypotTriggered) {
      notes.add(MorningNote.honeypot);
    }

    if (useKill) {
      killUsed = true;
      final t = _sel['kill']?.firstOrNull;
      if (t != null) deaths.add(t);
    }

    if (!outage && night.isEven) {
      final t = _sel['purple']?.firstOrNull;
      if (t != null) deaths.add(t);
    }

    // Phishing worked: the Red Team took a second victim with the stolen
    // credentials. That one cannot be restored.
    if (ev == EventCard.phishing && !phishSpotted) {
      final second = _sel['red']?.elementAtOrNull(1);
      if (second != null) deaths.add(second);
    }
    if (ev == EventCard.phishing && phishSpotted) {
      notes.add(MorningNote.phishSpotted);
    }

    morningIds = _eliminate(deaths);
    morningNotes = notes;
    voteBanned = {};

    // New day.
    phase = GamePhase.day;
    dayStage = DayStage.morning;
    inChain = false;
    noticeIds = [];
    verdictIds = [];
    electionToday = false;
    skipDebate = false;
    skipVote = false;
    debateSeconds = 180;
    ddosOrder = [];
    ddosIndex = 0;
    todayEvent = null;
    nightEvent = null;
    _clearQuiz();
    _sel.clear();
    _none.clear();
    restore = false;
    kill = false;
  }

  // ---------------------------------------------------------------------------
  // Eliminations and chain reactions
  // ---------------------------------------------------------------------------

  /// Takes machines down, applying VPN links and queuing Dead Man's Switch and
  /// CISO succession. Returns every machine that actually went down.
  List<int> _eliminate(Iterable<int> ids) {
    final out = <int>[];
    void down(int id) {
      final p = players[id];
      if (!p.alive) return;
      p.alive = false;
      out.add(id);
      if (p.role == RoleId.deadMansSwitch) pendingDms.add(id);
      if (ciso == id) {
        ciso = null;
        pendingCisoFrom = id;
      }
      if (link.length == 2 && link.contains(id)) {
        down(link.firstWhere((x) => x != id));
      }
    }

    for (final id in ids) {
      down(id);
    }
    return out;
  }

  void _beginChain({required bool thenNight}) {
    _thenNight = thenNight;
    inChain = true;
    noticeIds = [];
    _normalizeChain();
    if (!_chainPending) _finishChain();
  }

  bool get _chainPending => pendingDms.isNotEmpty || pendingCisoFrom != null;

  void _normalizeChain() {
    if (alivePlayers.isEmpty) {
      pendingDms.clear();
      pendingCisoFrom = null;
      return;
    }
    // No need to name a successor once the game is decided.
    if (pendingDms.isEmpty && pendingCisoFrom != null && checkWinner() != null) {
      pendingCisoFrom = null;
    }
  }

  void _confirmChain() {
    if (pendingDms.isNotEmpty) {
      pendingDms.removeAt(0);
      final target = _sel['dms']?.firstOrNull;
      _sel.remove('dms');
      _none.remove('dms');
      noticeIds = target == null ? [] : _eliminate([target]);
    } else if (pendingCisoFrom != null) {
      ciso = _sel['succession']?.firstOrNull;
      _sel.remove('succession');
      pendingCisoFrom = null;
      noticeIds = [];
    }
    _normalizeChain();
    if (!_chainPending) _finishChain();
  }

  void _finishChain() {
    inChain = false;
    final w = checkWinner();
    if (w != null) {
      phase = GamePhase.end;
      winner = w;
      return;
    }
    if (_thenNight) {
      _beginNight();
    } else {
      final vis = _visibleStages();
      dayStage = vis.length > 1 ? vis[1] : vis.first;
      _enterStage();
    }
  }

  // ---------------------------------------------------------------------------
  // Day flow
  // ---------------------------------------------------------------------------

  List<DayStage> _visibleStages() {
    final events = expert && night >= 2;
    return [
      DayStage.morning,
      if (electionToday || ciso == null) DayStage.election,
      if (events) DayStage.event,
      if (events && !_quizSkipped) ...[
        DayStage.quiz,
        DayStage.quizAnswer,
        DayStage.eventResult,
      ],
      if (!skipDebate) DayStage.debate,
      DayStage.vote,
    ];
  }

  void _dayPrimary() {
    switch (dayStage) {
      case DayStage.morning:
        _beginChain(thenNight: false);
      case DayStage.election:
      case DayStage.event:
      case DayStage.quiz:
      case DayStage.eventResult:
        _goNextStage();
      case DayStage.quizAnswer:
        _resolveQuiz();
        _goNextStage();
      case DayStage.debate:
        if (activeEvent == EventCard.ddos && ddosIndex < ddosOrder.length - 1) {
          ddosIndex++;
        } else {
          _goNextStage();
        }
      case DayStage.vote:
        if (skipVote) {
          verdictIds = [];
          _beginChain(thenNight: true);
        } else {
          final pick = _sel['vote']?.firstOrNull;
          verdictIds = pick == null ? [] : _eliminate([pick]);
          _sel.remove('vote');
          _none.remove('vote');
          dayStage = DayStage.verdict;
        }
      case DayStage.verdict:
        _beginChain(thenNight: true);
    }
  }

  void _goNextStage() {
    final vis = _visibleStages();
    final i = vis.indexOf(dayStage);
    dayStage = vis[min(i + 1, vis.length - 1)];
    _enterStage();
  }

  void _enterStage() {
    switch (dayStage) {
      case DayStage.election:
        electionToday = true;
      case DayStage.event:
        if (todayEvent == null) _drawEvent();
      case DayStage.debate:
        if (activeEvent == EventCard.ddos && ddosOrder.isEmpty) _buildDdosOrder();
      default:
        break;
    }
  }

  /// Draws today's Event. Nothing is applied yet: the quiz decides.
  void _drawEvent() {
    if (_deck.isEmpty) {
      _deck
        ..addAll(EventCard.values)
        ..shuffle(rng);
    }
    _setDrawn(_deck.removeLast());
  }

  void _setDrawn(EventCard card) {
    todayEvent = card;
    eventOutcome = EventOutcome.pending;
    quizCorrect = null;
    quizOrder = [0, 1, 2]..shuffle(rng);
    _quizSkipped = false;
    phishSpotted = false;
    if (card == EventCard.phishing) phishEmail = rng.nextInt(phishEmails.length);
    _resetEventEffects();
  }

  /// Blue Events need more than half right answers, Red Events are blocked by
  /// more than half right answers, Chaos Events always happen.
  void _resolveQuiz() {
    final card = todayEvent;
    if (card == null) return;
    final majority = (quizCorrect ?? 0) * 2 > alivePlayers.length;
    if (card == EventCard.phishing) phishSpotted = majority;
    final happens = switch (card.info.side) {
      EventSide.blue => majority,
      EventSide.red => !majority,
      EventSide.chaos => true,
    };
    _resetEventEffects();
    eventOutcome = happens ? EventOutcome.happens : EventOutcome.blocked;
    if (happens) _applyEffects(card);
  }

  void _clearQuiz() {
    eventOutcome = EventOutcome.pending;
    quizCorrect = null;
    _quizSkipped = false;
  }

  void _resetEventEffects() {
    skipDebate = false;
    skipVote = false;
    debateSeconds = 180;
    ddosOrder = [];
    ddosIndex = 0;
  }

  /// Day effects of an Event that happens. Night effects are read from
  /// [nightEvent] by the night script.
  void _applyEffects(EventCard card) {
    switch (card) {
      case EventCard.blackFridayRush:
        debateSeconds = 60;
      case EventCard.remoteWorkDay:
        skipDebate = true;
      case EventCard.maintenanceWindow:
        skipVote = true;
      case EventCard.ddos:
        _buildDdosOrder();
      default:
        break;
    }
  }

  /// Everyone alive speaks once, starting with the player to the left of the
  /// CISO. Players are entered in clockwise seating order, so "left" is the
  /// next seat.
  void _buildDdosOrder() {
    final start = ciso ?? -1;
    final alive = alivePlayers.map((p) => p.id).toList();
    ddosOrder = [
      ...alive.where((i) => i > start),
      ...alive.where((i) => i <= start),
    ];
    ddosIndex = 0;
  }

  String _join(List<String> names) {
    if (names.length <= 1) return names.join();
    return '${names.sublist(0, names.length - 1).join(', ')}${tr(' and ', ' et ')}${names.last}';
  }

  List<TileSpec> _tiles({
    required Set<int> selected,
    bool Function(Player p)? lock,
  }) =>
      players
          .map((p) => TileSpec(
                id: p.id,
                name: p.name,
                team: p.team,
                selected: selected.contains(p.id),
                locked: !p.alive || (lock?.call(p) ?? false),
                dead: !p.alive,
              ))
          .toList();
}
