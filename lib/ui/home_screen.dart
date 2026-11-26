import 'package:flutter/material.dart';
import '../i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';
import 'rules_screen.dart';
import 'settings_sheet.dart';
import 'widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNewGame});

  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    if (isShortLandscape(context)) return _landscape(context);
    // Small phones get tighter spacing so everything still fits.
    final compact = MediaQuery.sizeOf(context).height < 700;
    return NeonBackground(
      mood: Mood.night,
      child: _withSettings(
        Padding(
          padding: EdgeInsets.fromLTRB(20, compact ? 32 : 96, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ..._brand(compact),
              const Spacer(),
              ..._actions(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Phone held sideways: brand on the left, actions on the right.
  Widget _landscape(BuildContext context) => NeonBackground(
        mood: Mood.night,
        maxWidth: 820,
        child: _withSettings(Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: _brand(true)),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _actions(context),
                ),
              ),
            ],
          ),
        )),
      );

  /// Sound and Narrator settings, in the top-right corner.
  Widget _withSettings(Widget child) => Stack(
        fit: StackFit.expand,
        children: [
          child,
          const Positioned(top: 4, right: 4, child: SettingsButton()),
        ],
      );

  List<Widget> _brand(bool compact) => [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: SvgPicture.asset(
            'assets/brand/logo_typo.svg',
            semanticsLabel: 'Insider Threat',
          ),
        ),
                SizedBox(height: compact ? 16 : 24),

        TagChip(tr('Narrator companion', 'Compagnon du Narrateur')),
        SizedBox(height: compact ? 24 : 44),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            tr('A social deduction game on a compromised network.', 'Un jeu de déduction sociale sur un réseau compromis.'),
            textAlign: TextAlign.center,
            style: AppText.body(16,
                weight: FontWeight.w400, color: AppColors.textSoft, height: 1.5),
          ),
        ),
      ];

  List<Widget> _actions(BuildContext context) => [
        NeonButton(label: tr('New game', 'Nouvelle partie'), onPressed: onNewGame),
        const SizedBox(height: 12),
        NeonButton(
          label: tr('Rules', 'Règles'),
          variant: NeonVariant.ghost,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const RulesScreen()),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: Lbl(tr('5-14 players + 1 Narrator · 15-40 min', '5-14 joueurs + 1 Narrateur · 15-40 min'), align: TextAlign.center),
        ),
      ];
}
