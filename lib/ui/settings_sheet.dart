/// Sound and Narrator help settings, opened from a small button on the home,
/// setup and game screens.
library;

import 'package:flutter/material.dart';
import '../i18n.dart';

import '../app_settings.dart';
import '../theme/app_theme.dart';
import 'widgets.dart';

Future<void> showSettingsSheet(BuildContext context) {
  FocusScope.of(context).unfocus();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const SafeArea(child: _SettingsSheet()),
  );
}

/// Icon button that opens the settings. Its icon follows the sound state.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: AppSettings.instance,
        builder: (context, _) {
          final s = AppSettings.instance;
          return IconButton(
            tooltip: tr('Settings', 'Paramètres'),
            onPressed: () => showSettingsSheet(context),
            icon: Icon(
              s.gain == 0 ? Icons.volume_off_rounded : Icons.tune_rounded,
              color: AppColors.muted,
            ),
          );
        },
      );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: AppSettings.instance,
        builder: (context, _) {
          final s = AppSettings.instance;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr('Settings', 'Paramètres').toUpperCase(), style: AppText.ui(28, weight: FontWeight.w700)),
                const SizedBox(height: 18),
                Lbl(tr('Language', 'Langue')),
                const SizedBox(height: 8),
                // Each language is written in its own language. Switching
                // applies at once, even in the middle of a game.
                SegmentedButton<AppLanguage>(
                  segments: const [
                    ButtonSegment(value: AppLanguage.en, label: Text('English')),
                    ButtonSegment(value: AppLanguage.fr, label: Text('Français')),
                  ],
                  selected: {s.language},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) => s.setLanguage(v.first),
                  style: SegmentedButton.styleFrom(
                    foregroundColor: AppColors.textSoft,
                    selectedForegroundColor: AppColors.onAccent,
                    selectedBackgroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.line),
                    textStyle: AppText.body(15, weight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 18),
                Lbl(tr('Sound', 'Son')),
                const SizedBox(height: 4),
                _SwitchRow(
                  title: tr('Sound', 'Son'),
                  sub: s.soundOn
                      ? tr('Ambience and sound effects play', "L'ambiance et les effets sonores sont actifs")
                      : tr('Everything is muted', 'Tout est coupé'),
                  value: s.soundOn,
                  onChanged: s.setSoundOn,
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: s.soundOn ? tr('Mute', 'Couper le son') : tr('Unmute', 'Remettre le son'),
                      onPressed: () => s.setSoundOn(!s.soundOn),
                      icon: Icon(
                        s.gain == 0 ? Icons.volume_off_rounded : Icons.volume_down_rounded,
                        color: AppColors.muted,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: s.volume,
                        onChanged: s.setVolume,
                        activeColor: s.soundOn ? AppColors.primary : AppColors.line,
                        inactiveColor: AppColors.line,
                        label: '${(s.volume * 100).round()} %',
                        divisions: 20,
                        semanticFormatterCallback: (v) =>
                            tr('Volume ${(v * 100).round()} percent', 'Volume ${(v * 100).round()} pour cent'),
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${(s.volume * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: AppText.mono(13, color: AppColors.textSoft),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Lbl(tr('Narrator', 'Narrateur')),
                const SizedBox(height: 4),
                _SwitchRow(
                  title: tr('Narrator tips', 'Conseils au Narrateur'),
                  sub: s.narratorTips
                      ? tr('Beginner: each step explains what to do, with reminders',
                          'Débutant : chaque étape explique quoi faire, avec des rappels')
                      : tr('Experienced: only the lines to read', 'Expérimenté : seulement les phrases à lire'),
                  value: s.narratorTips,
                  onChanged: s.setNarratorTips,
                ),
              ],
            ),
          );
        },
      );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.sub,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.body(16, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(sub, style: AppText.body(13, color: AppColors.muted)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              thumbColor: const WidgetStatePropertyAll(AppColors.text),
              trackColor: WidgetStateProperty.resolveWith(
                (st) => st.contains(WidgetState.selected) ? AppColors.primary : AppColors.line,
              ),
            ),
          ],
        ),
      );
}
