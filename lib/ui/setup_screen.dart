import 'package:flutter/material.dart';
import '../i18n.dart';

import '../game/compositions.dart';
import '../game/models.dart';
import '../game/setup_controller.dart';
import '../theme/app_theme.dart';
import 'scan_screen.dart';
import 'settings_sheet.dart';
import 'widgets.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({
    super.key,
    required this.setup,
    required this.onBack,
    required this.onStart,
  });

  final SetupController setup;
  final VoidCallback onBack;
  final VoidCallback onStart;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late final List<TextEditingController> _names = [
    for (var i = 0; i < maxPlayers; i++)
      TextEditingController(text: widget.setup.names[i]),
  ];

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _confirmReset() async {
    FocusScope.of(context).unfocus();
    if (!widget.setup.hasPlayerData) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Reset the players?', 'Réinitialiser les joueurs ?').toUpperCase(), style: AppText.ui(20, weight: FontWeight.w700)),
        content: Text(tr('Every name and role card will be cleared.', 'Tous les noms et toutes les cartes seront effacés.'), style: AppText.body(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Cancel', 'Annuler')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Reset', 'Réinitialiser'), style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    for (final c in _names) {
      c.clear();
    }
    widget.setup.resetPlayers();
  }

  void _openScan([int? player]) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ScanScreen(setup: widget.setup, startAt: player),
    ));
  }

  Future<void> _pickRole(int player) async {
    final s = widget.setup;
    final counts = s.assignedCounts;
    final target = s.recommended.counts;
    final choice = await showModalBottomSheet<RoleId>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                child: Lbl(tr('Role card of player ${player + 1}', 'Carte du joueur ${player + 1}')),
              ),
              for (final r in roleDisplayOrder)
                ListTile(
                  enabled: !s.isRoleTaken(r, exceptPlayer: player) &&
                      (r != RoleId.purple || s.count >= purpleMinPlayers),
                  selected: s.roles[player] == r,
                  selectedTileColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: TeamPerson(r.info.team),
                  minLeadingWidth: 12,
                  title: Text(r.info.name,
                      style: AppText.body(16, weight: FontWeight.w600)),
                  subtitle: Text(r.info.character, style: AppText.body(13, color: AppColors.muted)),
                  trailing: Text(
                    '${counts[r] ?? 0}/${target[r] ?? 0}',
                    style: AppText.body(13, color: AppColors.muted),
                  ),
                  onTap: () => Navigator.pop(ctx, r),
                ),
            ],
          ),
        ),
      ),
    );
    if (choice != null) s.setRole(player, choice);
  }

  @override
  Widget build(BuildContext context) {
    return NeonBackground(
      mood: Mood.night,
      child: ListenableBuilder(
        listenable: widget.setup,
        builder: (context, _) {
          final s = widget.setup;
          final rec = s.recommended;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: widget.onBack,
                      child: Text(tr('‹ Back', '‹ Retour'),
                          style: AppText.body(15, color: AppColors.muted)),
                    ),
                    const Spacer(),
                    const SizedBox(width: 4),
                    const SettingsButton(),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  children: [
                    Text(tr('Set the table', 'Préparer la table').toUpperCase(),
                        style: AppText.ui(32, weight: FontWeight.w700, height: 1.05)),
                    const SizedBox(height: 14),
                    _CountRow(
                      count: s.count,
                      onInfo: () => _showRecommended(context, s.count, rec),
                      onMinus: s.count > minPlayers
                          ? () => s.setCount(s.count - 1)
                          : null,
                      onPlus: s.count < maxPlayers
                          ? () => s.setCount(s.count + 1)
                          : null,
                    ),
                    const SizedBox(height: 24),
                    NeonButton(
                      label: tr('Scan the cards', 'Scanner les cartes'),
                      height: 50,
                      fontSize: 14,
                      onPressed: () => _openScan(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: NeonButton(
                            label: tr('Deal at random', 'Distribuer au hasard'),
                            variant: NeonVariant.ghost,
                            height: 46,
                            fontSize: 13,
                            onPressed: s.fillRandom,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NeonButton(
                            label: tr('Reset players', 'Réinitialiser'),
                            variant: NeonVariant.ghost,
                            height: 46,
                            fontSize: 13,
                            onPressed: _confirmReset,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Lbl('')),
                        Text('${s.countTeam(Team.red)}',
                            style: AppText.body(14, weight: FontWeight.w600)),
                        const SizedBox(width: 5),
                        const TeamPerson(Team.red),
                        const SizedBox(width: 12),
                        Text('${s.countTeam(Team.blue)}',
                            style: AppText.body(14, weight: FontWeight.w600)),
                        const SizedBox(width: 5),
                        const TeamPerson(Team.blue),
                        const SizedBox(width: 12),
                        Text('${s.countTeam(Team.purple)}',
                            style: AppText.body(14, weight: FontWeight.w600)),
                        const SizedBox(width: 5),
                        const TeamPerson(Team.purple),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < s.count; i++)
                      _PlayerRow(
                        key: ValueKey(i),
                        index: i,
                        controller: _names[i],
                        role: s.roles[i],
                        scanned: s.cards[i] != null,
                        last: i == s.count - 1,
                        onName: (v) => s.setName(i, v),
                        onRole: () => _pickRole(i),
                        onScan: () => _openScan(i),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(tr('Expert mode (Event cards)', 'Mode Expert (cartes Event)'),
                              style: AppText.body(15, weight: FontWeight.w600)),
                        ),
                        Switch(
                          value: s.expert,
                          onChanged: s.setExpert,
                          thumbColor:
                              const WidgetStatePropertyAll(AppColors.text),
                          trackColor: WidgetStateProperty.resolveWith(
                            (st) => st.contains(WidgetState.selected)
                                ? AppColors.primary
                                : AppColors.line,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: NeonButton(
                  label: s.blocker ?? tr('Start the game', 'Lancer la partie'),
                  onPressed: s.canStart ? widget.onStart : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.count,
    required this.onMinus,
    required this.onPlus,
    required this.onInfo,
  });

  final int count;
  final VoidCallback onInfo;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Text(tr('Players', 'Joueurs'), style: AppText.body(16, weight: FontWeight.w700)),
            IconButton(
              tooltip: tr('Recommended roles', 'Rôles conseillés'),
              onPressed: onInfo,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.info_outline_rounded,
                  size: 20, color: AppColors.muted),
            ),
            const Spacer(),
            IconButton(
              tooltip: tr('Remove a player', 'Retirer un joueur'),
              onPressed: onMinus,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 40,
              child: Text('$count',
                  textAlign: TextAlign.center,
                  style: AppText.mono(22,
                      weight: FontWeight.w700, color: AppColors.text)),
            ),
            IconButton(
              tooltip: tr('Add a player', 'Ajouter un joueur'),
              onPressed: onPlus,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      );
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    super.key,
    required this.index,
    required this.controller,
    required this.role,
    required this.scanned,
    required this.last,
    required this.onName,
    required this.onRole,
    required this.onScan,
  });

  final int index;
  final TextEditingController controller;
  final RoleId? role;
  final bool scanned;

  /// Last row: the keyboard shows "done" instead of "next".
  final bool last;
  final ValueChanged<String> onName;
  final VoidCallback onRole;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.only(left: 14, right: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            if (role != null)
              TeamPerson(role!.info.team)
            else
              const Icon(Icons.person, size: 18, color: AppColors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onName,
                textCapitalization: TextCapitalization.words,
                textInputAction: last ? TextInputAction.done : TextInputAction.next,
                // Tapping anywhere else closes the keyboard.
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                style: AppText.body(18, weight: FontWeight.w600),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: tr('Player ${index + 1}', 'Joueur ${index + 1}'),
                  hintStyle: AppText.body(18, color: AppColors.disabledText),
                ),
              ),
            ),
            IconButton(
              tooltip: scanned
                  ? tr('Card scanned. Scan again for player ${index + 1}', 'Carte scannée. Scanner à nouveau pour le joueur ${index + 1}')
                  : tr('Scan the card of player ${index + 1}', 'Scanner la carte du joueur ${index + 1}'),
              onPressed: onScan,
              icon: Icon(
                Icons.qr_code_scanner,
                size: 20,
                color: scanned ? AppColors.primary : AppColors.muted,
              ),
            ),
            TextButton(
              onPressed: onRole,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(
                  role?.info.name ?? tr('Pick role', 'Choisir un rôle'),
                  textAlign: TextAlign.right,
                  style: AppText.body(12.5,
                      color: role == null ? AppColors.secondarySoft : AppColors.textSoft),
                ),
              ),
            ),
          ],
        ),
      );
}

/// Bottom sheet listing the rulebook composition for [players].
void _showRecommended(BuildContext context, int players, Composition rec) {
  Widget row(RoleId role, int n) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            TeamPerson(role.info.team),
            const SizedBox(width: 12),
            Expanded(
              child: Text(role.info.name,
                  style: AppText.body(16, weight: FontWeight.w600)),
            ),
            Text('×$n',
                style: AppText.mono(16,
                    weight: FontWeight.w700, color: AppColors.text)),
          ],
        ),
      );

  showModalBottomSheet<void>(
    context: context,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr('Recommended', 'Conseillé').toUpperCase(), style: AppText.ui(28, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(tr('For $players players, from the rulebook.', 'Pour $players joueurs, selon les règles.'),
                style: AppText.body(14, color: AppColors.muted)),
            const SizedBox(height: 12),
            for (final e in rec.counts.entries) row(e.key, e.value),
          ],
        ),
      ),
    ),
  );
}
