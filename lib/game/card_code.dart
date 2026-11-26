/// The text printed in each card's QR code: `INSIDERTHREAT:1:<role>:<nn>`.
///
/// `1` is the format version, `<role>` a role slug and `<nn>` the card number
/// within that role (two digits).
library;

import 'models.dart';

const cardCodePrefix = 'INSIDERTHREAT';
const cardCodeVersion = '1';

const Map<RoleId, String> roleSlugs = {
  RoleId.red: 'red',
  RoleId.defender: 'defender',
  RoleId.threatHunter: 'threat_hunter',
  RoleId.socAnalyst: 'soc_analyst',
  RoleId.incidentResponder: 'incident_responder',
  RoleId.deadMansSwitch: 'dead_mans_switch',
  RoleId.networkEngineer: 'network_engineer',
  RoleId.purple: 'purple',
};

class CardCode {
  const CardCode({required this.role, required this.number});

  final RoleId role;
  final int number;

  /// Identifies one physical card, for example `defender:07`.
  String get id => '${roleSlugs[role]}:${number.toString().padLeft(2, '0')}';

  String get text => '$cardCodePrefix:$cardCodeVersion:$id';

  String get label => role.info.unique
      ? role.info.name
      : '${role.info.name} #${number.toString().padLeft(2, '0')}';
}

/// Cards printed with another card's QR code: printed code id -> real card.
const Map<String, CardCode> misprintedCards = {
  'red:04': CardCode(role: RoleId.defender, number: 2),
  'defender:02': CardCode(role: RoleId.red, number: 4),
  'purple:01': CardCode(role: RoleId.networkEngineer, number: 1),
  'dead_mans_switch:01': CardCode(role: RoleId.threatHunter, number: 1),
};

/// Returns null for anything that is not an Insider Threat card.
CardCode? parseCardCode(String? raw) {
  if (raw == null) return null;
  final parts = raw.trim().split(':');
  if (parts.length != 4) return null;
  if (parts[0].toUpperCase() != cardCodePrefix) return null;
  if (parts[1] != cardCodeVersion) return null;
  RoleId? role;
  for (final e in roleSlugs.entries) {
    if (e.value == parts[2].toLowerCase()) role = e.key;
  }
  final number = int.tryParse(parts[3]);
  if (role == null || number == null || number < 1 || number > 99) return null;
  final card = CardCode(role: role, number: number);
  return misprintedCards[card.id] ?? card;
}
