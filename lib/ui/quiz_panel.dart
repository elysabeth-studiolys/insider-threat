import 'package:flutter/material.dart';

import '../game/events.dart';
import '../game/guide_step.dart';
import '../theme/app_theme.dart';
import 'widgets.dart';

/// The Expert mode quiz: the question, its 3 numbered answers and, once the
/// answer is revealed, the explanation and the count of right answers.
class QuizPanel extends StatelessWidget {
  const QuizPanel({super.key, required this.spec, required this.onCount});

  final QuizSpec spec;
  final ValueChanged<int> onCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (spec.email != null) ...[
                _EmailCard(email: spec.email!),
                const SizedBox(height: 14),
              ],
              const Lbl('Question', color: AppColors.primarySoft),
              const SizedBox(height: 6),
              Text(spec.question,
                  style: AppText.body(18, weight: FontWeight.w700, height: 1.35)),
              const SizedBox(height: 14),
              for (var i = 0; i < spec.answers.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _AnswerRow(
                  number: i + 1,
                  text: spec.answers[i],
                  state: !spec.revealed
                      ? _AnswerState.open
                      : i == spec.correct
                          ? _AnswerState.right
                          : _AnswerState.wrong,
                ),
              ],
            ],
          ),
        ),
        if (spec.revealed) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: .35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Lbl('Why', color: AppColors.primarySoft),
                const SizedBox(height: 4),
                Text(spec.explanation,
                    style: AppText.body(15,
                        weight: FontWeight.w400, color: AppColors.textSoft, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CountPicker(spec: spec, onCount: onCount),
        ],
      ],
    );
  }
}

enum _AnswerState { open, right, wrong }

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({required this.number, required this.text, required this.state});

  final int number;
  final String text;
  final _AnswerState state;

  @override
  Widget build(BuildContext context) {
    final right = state == _AnswerState.right;
    final wrong = state == _AnswerState.wrong;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: wrong ? .45 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: right ? AppColors.primary : AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: right ? AppColors.primaryGradient : null,
                color: right ? null : AppColors.bg,
                shape: BoxShape.circle,
              ),
              child: Text('$number',
                  style: AppText.mono(15,
                      weight: FontWeight.w700,
                      color: right ? AppColors.onAccent : AppColors.text)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: AppText.body(15,
                      weight: right ? FontWeight.w700 : FontWeight.w500, height: 1.35)),
            ),
            if (right) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}

/// The Narrator taps how many players found the right answer.
class _CountPicker extends StatelessWidget {
  const _CountPicker({required this.spec, required this.onCount});

  final QuizSpec spec;
  final ValueChanged<int> onCount;

  @override
  Widget build(BuildContext context) {
    final happens = spec.happens;
    final custom = spec.majority == null
        ? null
        : spec.majority!
            ? spec.majorityRight
            : spec.majorityWrong;
    final verdict = happens == null
        ? 'More than half = at least ${spec.needed} of ${spec.alive}.'
        : custom ?? switch (spec.side) {
            EventSide.chaos => 'Chaos Event: it happens whatever the answers.',
            _ => spec.majority!
                ? 'More than half were right: the Event ${happens ? 'happens' : 'is blocked'}.'
                : 'Not enough right answers: the Event ${happens ? 'happens' : 'is blocked'}.',
          };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Lbl('Players who found the right answer (out of ${spec.alive})'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var n = 0; n <= spec.alive; n++)
              _CountChip(
                n: n,
                selected: spec.correctCount == n,
                onTap: () => onCount(n),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(verdict,
            style: AppText.body(14,
                weight: FontWeight.w600,
                color: happens == null
                    ? AppColors.muted
                    : happens
                        ? AppColors.primarySoft
                        : AppColors.secondarySoft,
                height: 1.4)),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.n,
    required this.selected,
    required this.onTap,
  });

  final int n;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Semantics(
      button: true,
      selected: selected,
      label: '$n right answers',
      child: Pressable(
        onTap: onTap,
        width: 48,
        height: 48,
        color: AppColors.surface,
        border: selected ? AppColors.primary : null,
        borderRadius: radius,
            child: Center(
              child: ExcludeSemantics(
                child: Text('$n',
                    style: AppText.mono(17,
                        weight: FontWeight.w700,
                        color: selected ? AppColors.primary : AppColors.text)),
              ),
            ),
      ),
    );
  }
}


/// The email judged in the Phishing Campaign quiz, shown like a mail client.
class _EmailCard extends StatelessWidget {
  const _EmailCard({required this.email});

  final PhishEmail email;

  @override
  Widget build(BuildContext context) {
    TextStyle meta(Color c) => AppText.body(13, color: c, height: 1.4);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.textSoft),
              const SizedBox(width: 8),
              Expanded(child: Text('Inbox', style: AppText.body(13, weight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'From  ', style: meta(AppColors.muted)),
            TextSpan(text: email.from, style: meta(AppColors.text)),
          ])),
          const SizedBox(height: 2),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'Subject  ', style: meta(AppColors.muted)),
            TextSpan(
                text: email.subject,
                style: AppText.body(13, weight: FontWeight.w700, height: 1.4)),
          ])),
          const Divider(height: 20, color: AppColors.line),
          Text(email.body,
              style: AppText.body(15,
                  weight: FontWeight.w400, color: AppColors.textSoft, height: 1.5)),
        ],
      ),
    );
  }
}
