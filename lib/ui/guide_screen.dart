import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../game/game_controller.dart';
import '../game/guide_step.dart';
import '../theme/app_theme.dart';
import 'event_draw/event_draw_panel.dart';
import 'quiz_panel.dart';
import 'role_reveal.dart';
import 'settings_sheet.dart';
import 'widgets.dart';

/// The Narrator's main screen, used for every night and day step.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key, required this.game, required this.onQuit});

  final GameController game;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final step = game.currentStep;
    final isNight = game.phase == GamePhase.night;
    final phaseLabel =
        '${isNight ? 'Night' : 'Day'} ${game.night.toString().padLeft(2, '0')}';
    final pageKey =
        '${game.phase.name}-${game.night}-${step.kind.name}-${step.stepNo}-${step.title}';

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
      child: Row(
        children: [
          TagChip(phaseLabel),
          const SizedBox(width: 8),
          Expanded(
            child: Lbl(
              step.progressLabel ?? 'Step ${step.stepNo} / ${step.total}',
              align: TextAlign.right,
            ),
          ),
          const SettingsButton(),
          IconButton(
            tooltip: 'Quit the game',
            onPressed: onQuit,
            icon: const Icon(Icons.close, color: AppColors.muted),
          ),
        ],
      ),
    );
    final body = Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: SingleChildScrollView(
          key: ValueKey(pageKey),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ListenableBuilder(
            listenable: AppSettings.instance,
            builder: (context, _) => _StepBody(game: game, step: step),
          ),
        ),
      ),
    );
    final back = NeonButton(
      label: 'Back',
      variant: NeonVariant.ghost,
      onPressed: step.canBack ? game.back : null,
    );
    final primary = NeonButton(
      label: step.primaryLabel,
      variant: step.primaryStyle == PrimaryStyle.red
          ? NeonVariant.red
          : NeonVariant.primary,
      onPressed: step.canContinue ? game.primary : null,
    );
    final landscape = isShortLandscape(context);

    if (landscape) {
      // Phone held sideways: the step scrolls on the left, actions stay in a
      // rail on the right so the text keeps the full height.
      return NeonBackground(
        mood: isNight ? Mood.night : Mood.day,
        maxWidth: 900,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: Column(children: [header, body])),
            SizedBox(
              width: 220,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 20, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [primary, const SizedBox(height: 10), back],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return NeonBackground(
      mood: isNight ? Mood.night : Mood.day,
      child: Column(
        children: [
          header,
          body,
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: back),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: primary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.game, required this.step});

  final GameController game;
  final GuideStep step;

  /// Picks a tile. When that completes a pick that reveals role cards
  /// (Threat Hunter), the cards open full screen right away.
  void _pick(BuildContext context, int id) {
    game.pick(id);
    final next = game.currentStep;
    if (next.reveal.isNotEmpty && game.sel(next.selKey ?? '').contains(id)) {
      showRoleReveal(context, viewer: next.revealTo, cards: next.reveal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[
      SegBar(current: step.stepNo, total: step.total),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Without a subtitle (night steps), who is concerned sits above the
          // title: team icon, names or "Everyone", and the tag.
          if (step.sub.isEmpty &&
              (step.kicker.isNotEmpty || step.team != null || step.tag != null))
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (step.team != null) TeamPerson(step.team!),
                if (step.kicker.isNotEmpty)
                  Text(
                    step.kicker,
                    style: AppText.body(15, color: AppColors.textSoft),
                  ),
                if (step.tag != null) TagChip(step.tag!, danger: true),
              ],
            )
          else if (step.sub.isNotEmpty && step.kicker.isNotEmpty)
            Lbl(step.kicker),
          if (step.kicker.isNotEmpty ||
              (step.sub.isEmpty && (step.team != null || step.tag != null)))
            const SizedBox(height: 6),
          Text(
            step.title.toUpperCase(),
            style: AppText.ui(34, weight: FontWeight.w700, height: 1.04),
          ),
          if (step.sub.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (step.team != null) TeamPerson(step.team!),
                Text(
                  step.sub,
                  style: AppText.body(15, color: AppColors.textSoft),
                ),
                if (step.tag != null) TagChip(step.tag!, danger: true),
              ],
            ),
          ],
        ],
      ),
      if (step.event != null)
        EventDrawPanel(
          key: ValueKey('draw-${game.night}-${step.event!.name}'),
          card: step.event!,
          animate: !game.eventRevealed,
          onRevealed: game.markEventRevealed,
        ),
      if (step.notice.isNotEmpty) DownList(entries: step.notice, compact: true),
      if (step.banner != null) BannerCard(text: step.banner!),
      SayCard(text: step.say),
      // Beginner help: what the Narrator does now. Hidden for experienced
      // Narrators (Settings > Narrator tips), like the reminder lines below.
      if (AppSettings.instance.narratorTips && step.todo.isNotEmpty)
        TipCard(text: step.todo),
      if (step.secret != null) SecretCard(text: step.secret!),
      if (step.quiz != null)
        QuizPanel(spec: step.quiz!, onCount: game.setQuizCorrect),
      if (step.report != null) DownList(entries: step.report!),
      if (step.ddos != null && step.ddos!.upcoming.isNotEmpty)
        Lbl('Next: ${step.ddos!.upcoming.join(' · ')}'),
      if (step.clock != null)
        CountdownClock(key: ValueKey(step.clock!.id), spec: step.clock!),
      if (step.tools != null)
        ToolsRow(
          spec: step.tools!,
          onRestore: game.toggleRestore,
          onKill: game.toggleKill,
        ),
      if (step.picker != null)
        PickerGrid(
          spec: step.picker!,
          onPick: (id) => _pick(context, id),
          onNone: game.pickNone,
        ),
      // Narrator reminders ("Show X the role card of Y"): beginner help too.
      if (AppSettings.instance.narratorTips)
        for (final r in step.results) ResultRow(line: r),
      if (step.reveal.isNotEmpty)
        NeonButton(
          label: step.reveal.length > 1
              ? 'Show the cards again'
              : 'Show the card again',
          variant: NeonVariant.ghost,
          height: 48,
          fontSize: 14,
          onPressed: () => showRoleReveal(
            context,
            viewer: step.revealTo,
            cards: step.reveal,
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          blocks[i],
        ],
      ],
    );
  }
}
