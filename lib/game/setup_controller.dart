/// Setup: the Narrator enters player names (in clockwise seating order) and
/// which role card each one received.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import 'card_code.dart';
import 'compositions.dart';
import 'models.dart';
import '../i18n.dart';

export 'card_code.dart' show CardCode;

enum ScanOutcome {
  /// The role was given to the player.
  assigned,

  /// This card was already scanned for this player: nothing changes.
  sameCard,

  /// This card already belongs to another player.
  cardUsed,

  /// Another player already holds this unique role.
  roleTaken,
}

class ScanResult {
  const ScanResult(this.outcome,
      {required this.card, required this.player, this.other});

  final ScanOutcome outcome;
  final CardCode card;
  final int player;

  /// The other player involved, for [ScanOutcome.cardUsed] and
  /// [ScanOutcome.roleTaken].
  final int? other;
}

class SetupController extends ChangeNotifier {
  int count = 8;
  bool expert = true;
  final List<String> names = List.filled(maxPlayers, '');
  final List<RoleId?> roles = List.filled(maxPlayers, null);

  /// Id of the physical card scanned for each player (null = picked by hand).
  final List<String?> cards = List.filled(maxPlayers, null);

  Composition get recommended => recommendedComposition(count);

  String displayName(int i) =>
      names[i].trim().isEmpty ? tr('Player ${i + 1}', 'Joueur ${i + 1}') : names[i].trim();

  /// First player, in seating order, who has no role yet.
  int? get nextUnassigned {
    for (var i = 0; i < count; i++) {
      if (roles[i] == null) return i;
    }
    return null;
  }

  /// Gives [player] the role of the scanned card.
  ScanResult assignCard(int player, CardCode card) {
    for (var i = 0; i < count; i++) {
      if (cards[i] == card.id) {
        return ScanResult(
          i == player ? ScanOutcome.sameCard : ScanOutcome.cardUsed,
          card: card,
          player: player,
          other: i,
        );
      }
    }
    if (card.role.info.unique) {
      for (var i = 0; i < count; i++) {
        if (i != player && roles[i] == card.role) {
          return ScanResult(ScanOutcome.roleTaken,
              card: card, player: player, other: i);
        }
      }
    }
    roles[player] = card.role;
    cards[player] = card.id;
    notifyListeners();
    return ScanResult(ScanOutcome.assigned, card: card, player: player);
  }

  void setCount(int n) {
    count = n.clamp(minPlayers, maxPlayers);
    notifyListeners();
  }

  void setExpert(bool v) {
    expert = v;
    notifyListeners();
  }

  void setName(int i, String v) {
    names[i] = v;
    // Names do not affect validation: no rebuild needed.
  }

  void setRole(int i, RoleId? r) {
    roles[i] = r;
    cards[i] = null;
    notifyListeners();
  }

  /// A unique role can only be given once.
  bool isRoleTaken(RoleId r, {required int exceptPlayer}) {
    if (!r.info.unique) return false;
    for (var i = 0; i < count; i++) {
      if (i != exceptPlayer && roles[i] == r) return true;
    }
    return false;
  }

  Map<RoleId, int> get assignedCounts {
    final out = <RoleId, int>{};
    for (var i = 0; i < count; i++) {
      final r = roles[i];
      if (r != null) out[r] = (out[r] ?? 0) + 1;
    }
    return out;
  }

  int get assigned => assignedCounts.values.fold(0, (a, b) => a + b);

  int countTeam(Team t) =>
      assignedCounts.entries.where((e) => e.key.info.team == t).fold(0, (a, e) => a + e.value);

  /// Why the game cannot start yet, or null when it can.
  String? get blocker {
    if (assigned < count) {
      final left = count - assigned;
      return tr("Assign $left more ${left == 1 ? 'role' : 'roles'}",
          "Encore $left ${left == 1 ? 'rôle' : 'rôles'} à attribuer");
    }
    if (countTeam(Team.red) < 1) return tr('Add a Red Team card', 'Ajoutez une carte Red Team');
    if (countTeam(Team.blue) < 1) return tr('Add a Blue Team card', 'Ajoutez une carte Blue Team');
    if (count < purpleMinPlayers && countTeam(Team.purple) > 0) {
      return tr('Purple Team needs $purpleMinPlayers players', 'La Purple Team demande $purpleMinPlayers joueurs');
    }
    return null;
  }

  bool get canStart => blocker == null;

  /// Deals the recommended composition at random. Handy to test the app
  /// without physical cards.
  void fillRandom([Random? random]) {
    final pool = recommended.pool..shuffle(random ?? Random());
    for (var i = 0; i < maxPlayers; i++) {
      roles[i] = i < count ? pool[i] : null;
      cards[i] = null;
    }
    notifyListeners();
  }

  void clearRoles() {
    for (var i = 0; i < maxPlayers; i++) {
      roles[i] = null;
      cards[i] = null;
    }
    notifyListeners();
  }

  /// Clears every name, role and scanned card. The player count stays.
  void resetPlayers() {
    for (var i = 0; i < maxPlayers; i++) {
      names[i] = '';
      roles[i] = null;
      cards[i] = null;
    }
    notifyListeners();
  }

  bool get hasPlayerData =>
      names.any((n) => n.trim().isNotEmpty) || roles.any((r) => r != null);

  List<Player> buildPlayers() => [
        for (var i = 0; i < count; i++)
          Player(
            id: i,
            name: names[i].trim().isEmpty ? tr('Player ${i + 1}', 'Joueur ${i + 1}') : names[i].trim(),
            role: roles[i]!,
          ),
      ];
}
