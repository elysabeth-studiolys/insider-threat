import 'dart:async';

import 'package:flutter/material.dart';

import '../game/guide_step.dart';
import '../game/models.dart';
import '../theme/app_theme.dart';
import 'event_draw/sfx.dart';

enum Mood { night, day, endBlue, endRed }

/// True on a phone held sideways: wider than tall and too short for the
/// stacked portrait layout. Screens then move their actions to a side rail.
bool isShortLandscape(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width > size.height && size.height < 560;
}

/// Full-screen background with the prototype's soft glows.
class NeonBackground extends StatelessWidget {
  const NeonBackground({
    super.key,
    required this.mood,
    required this.child,
    this.maxWidth = 520,
  });

  final Mood mood;
  final Widget child;

  /// Width of the centred content column. Landscape layouts pass more.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final glow = switch (mood) {
      Mood.night => AppColors.primary.withValues(alpha: .11),
      Mood.day => AppColors.primary.withValues(alpha: .18),
      Mood.endBlue => AppColors.primary.withValues(alpha: .22),
      Mood.endRed => AppColors.teamRed.withValues(alpha: .28),
    };
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Faint illustration under the glows, kept low so text stays readable.
          const Positioned.fill(
            child: Image(
              image: AssetImage('assets/brand/background.webp'),
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              opacity: AlwaysStoppedAnimation(.28),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1, 1.05),
                  radius: .9,
                  colors: [
                    AppColors.secondary.withValues(alpha: .10),
                    AppColors.secondary.withValues(alpha: 0),
                  ],
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -1.15),
                    radius: 1.0,
                    colors: [glow, glow.withValues(alpha: 0)],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Lbl extends StatelessWidget {
  const Lbl(this.text, {super.key, this.color = AppColors.muted, this.align});

  final String text;
  final Color color;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    style: AppText.body(13, color: color, height: 1.35),
  );
}

class TagChip extends StatelessWidget {
  const TagChip(this.text, {super.key, this.danger = false});

  final String text;

  /// Warning tag, in the danger colour instead of the secondary one.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final base = danger ? AppColors.danger : AppColors.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: base.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        text,
        style: AppText.body(
          14,
          weight: FontWeight.w600,
          color: danger ? AppColors.dangerSoft : AppColors.secondarySoft,
        ),
      ),
    );
  }
}

class TeamPerson extends StatelessWidget {
  const TeamPerson(this.team, {super.key, this.size = 18});

  final Team team;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.team(team);
    return Semantics(
      label: team.label,
      child: Icon(
        Icons.person,
        size: size,
        color: c,
        shadows: [Shadow(color: c.withValues(alpha: .7), blurRadius: 8)],
      ),
    );
  }
}

enum NeonVariant { primary, red, ghost }

/// Tap target with no ripple: shows a 1px yellow border while pressed,
/// like the website's hover. [border] is the resting border (null = none).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.child,
    this.color,
    this.gradient,
    this.border,
    this.pressedBorder = AppColors.primary,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.width,
    this.height,
  });

  final VoidCallback? onTap;
  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final Color? border;

  /// Border while pressed. Tiles with a coloured accent pass that accent so
  /// the press does not flash yellow before the selection colour.
  final Color pressedBorder;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final double? width;
  final double? height;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final borderColor = enabled && _pressed
        ? widget.border ?? widget.pressedBorder
        : widget.border ?? Colors.transparent;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color,
          gradient: widget.gradient,
          shape: widget.shape,
          borderRadius: widget.shape == BoxShape.circle
              ? null
              : widget.borderRadius,
          border: Border.all(color: borderColor),
        ),
        child: widget.child,
      ),
    );
  }
}

class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = NeonVariant.primary,
    this.height = 56,
    this.fontSize = 16,
  });

  final String label;
  final VoidCallback? onPressed;
  final NeonVariant variant;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final Gradient? gradient = !enabled
        ? null
        : switch (variant) {
            NeonVariant.primary => AppColors.primaryGradient,
            NeonVariant.red => AppColors.dangerGradient,
            NeonVariant.ghost => null,
          };
    final bg = !enabled
        ? AppColors.disabledBg
        : variant == NeonVariant.ghost
        ? AppColors.surface
        : null;
    final fg = !enabled
        ? AppColors.disabledText
        : variant == NeonVariant.ghost
        ? AppColors.text
        : AppColors.onAccent;
    final Color? borderColor = !enabled
        ? null
        : switch (variant) {
            NeonVariant.primary => AppColors.primary,
            NeonVariant.red => AppColors.danger,
            NeonVariant.ghost => null,
          };
    final radius = BorderRadius.circular(16);
    return Pressable(
      onTap: onPressed,
      height: height,
      color: bg,
      gradient: gradient,
      border: borderColor,
      borderRadius: radius,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              fontSize,
              weight: FontWeight.w700,
              color: fg,
              spacing: .9,
            ),
          ),
        ),
      ),
    );
  }
}

class SegBar extends StatelessWidget {
  const SegBar({super.key, required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i < current ? null : AppColors.line,
                gradient: i < current ? AppColors.primaryGradient : null,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

/// The line the Narrator reads, typed out. Its height is reserved up front so
/// the page does not jump while typing.
class SayCard extends StatefulWidget {
  const SayCard({super.key, required this.text});

  final String text;

  @override
  State<SayCard> createState() => _SayCardState();
}

class _SayCardState extends State<SayCard> {
  Timer? _timer;
  int _typed = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _start();
    }
  }

  @override
  void didUpdateWidget(SayCard old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _start();
  }

  void _start() {
    _timer?.cancel();
    if (MediaQuery.disableAnimationsOf(context)) {
      _typed = widget.text.length;
      return;
    }
    _typed = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 22), (t) {
      if (_typed >= widget.text.length) {
        t.cancel();
        return;
      }
      setState(() => _typed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = AppText.body(20, height: 1.4);
    final shown = widget.text.substring(0, _typed.clamp(0, widget.text.length));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.secondary.withValues(alpha: .4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: widget.text,
            child: ExcludeSemantics(
              child: Stack(
                children: [
                  Visibility(
                    visible: false,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Text(widget.text, style: style),
                  ),
                  Text(shown, style: style),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PickerGrid extends StatelessWidget {
  const PickerGrid({
    super.key,
    required this.spec,
    required this.onPick,
    required this.onNone,
  });

  final PickerSpec spec;
  final ValueChanged<int> onPick;
  final VoidCallback onNone;

  Color get _accent => switch (spec.style) {
    PickStyle.blue => AppColors.teamBlue,
    PickStyle.red => AppColors.teamRed,
    PickStyle.violet => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Lbl(spec.label),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisExtent: 48,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: spec.tiles.length,
          itemBuilder: (_, i) {
            final t = spec.tiles[i];
            return _Tile(
              selected: t.selected,
              accent: _accent,
              onTap: t.locked ? null : () => onPick(t.id),
              child: Row(
                children: [
                  TeamPerson(t.team),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        15,
                        weight: FontWeight.w600,
                        decoration: t.dead ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (spec.noneLabel != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: _Tile(
              selected: spec.noneSelected,
              accent: _accent,
              onTap: onNone,
              child: Center(
                child: Text(
                  spec.noneLabel!,
                  style: AppText.body(15, weight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.selected,
    required this.accent,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final bool selected;
  final Color accent;
  final VoidCallback? onTap;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      child: Opacity(
        opacity: onTap == null ? .4 : 1,
        child: Pressable(
          onTap: onTap,
          color: AppColors.surface,
          border: selected ? accent : null,
          pressedBorder: accent,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class ToolsRow extends StatelessWidget {
  const ToolsRow({
    super.key,
    required this.spec,
    required this.onRestore,
    required this.onKill,
  });

  final ToolsSpec spec;
  final VoidCallback onRestore;
  final VoidCallback onKill;

  Widget _tool(
    String title,
    String sub,
    bool on,
    bool enabled,
    Color accent,
    VoidCallback cb,
  ) => Expanded(
    child: SizedBox(
      height: 66,
      child: _Tile(
        selected: on,
        accent: accent,
        onTap: enabled ? cb : null,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(14, weight: FontWeight.w700, spacing: .6),
            ),
            const SizedBox(height: 5),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                12,
                weight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _tool(
        'Backup restore',
        spec.restoreSub,
        spec.restoreOn,
        spec.restoreEnabled,
        AppColors.teamBlue,
        onRestore,
      ),
      const SizedBox(width: 8),
      _tool(
        'Kill process',
        spec.killSub,
        spec.killOn,
        spec.killEnabled,
        AppColors.danger,
        onKill,
      ),
    ],
  );
}

class CountdownClock extends StatefulWidget {
  const CountdownClock({super.key, required this.spec});

  final ClockSpec spec;

  @override
  State<CountdownClock> createState() => _CountdownClockState();
}

class _CountdownClockState extends State<CountdownClock> {
  late int _left = widget.spec.seconds;
  late int _max = widget.spec.seconds;
  bool _running = false;
  bool _started = false;
  Timer? _timer;

  /// The warning sound lasts 7 seconds: it starts here so it ends at 00:00.
  static const _warnAt = 7;
  bool _warning = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_running || _left == 0) return;
      setState(() => _left--);
      if (_left == _warnAt && !_warning) {
        _warning = true;
        Sfx.instance.play(SfxId.timerWarning);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopWarning();
    super.dispose();
  }

  void _stopWarning() {
    if (!_warning) return;
    _warning = false;
    Sfx.instance.stop(SfxId.timerWarning);
  }

  void _toggleRunning() {
    setState(() => _running = !_running);
    if (!_warning) return;
    _running
        ? Sfx.instance.resume(SfxId.timerWarning)
        : Sfx.instance.pause(SfxId.timerWarning);
  }

  String get _text =>
      '${(_left ~/ 60).toString().padLeft(2, '0')}:${(_left % 60).toString().padLeft(2, '0')}';

  void _start() => setState(() {
    _started = true;
    _running = true;
  });

  void _addMinute() => setState(() {
    _stopWarning();
    _left += 60;
    if (_left > _max) _max = _left;
  });

  String get _status {
    if (_left == 0) return "Time's up";
    if (!_started) return 'Ready';
    return _running ? 'Running' : 'Paused';
  }

  @override
  Widget build(BuildContext context) {
    final over = _left == 0;
    final big = widget.spec.controls;
    final ring = big ? 190.0 : 150.0;
    final accent = over ? AppColors.danger : AppColors.primary;
    // Empty ring until the clock is started, then it drains.
    final progress = !_started || _max == 0 ? 0.0 : _left / _max;
    return Semantics(
      label: '${widget.spec.label}: $_text, $_status',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Lbl(widget.spec.label),
          const SizedBox(height: 10),
          Center(
            child: SizedBox(
              width: ring,
              height: ring,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: progress),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (_, v, _) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: big ? 10 : 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.line,
                      color: accent,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _text,
                        style:
                            AppText.mono(
                              big ? 44 : 34,
                              weight: FontWeight.w700,
                              color: over
                                  ? AppColors.danger
                                  : _started
                                  ? AppColors.text
                                  : AppColors.textSoft,
                              height: 1,
                            ).copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _status,
                        style: AppText.body(
                          13,
                          color: over ? AppColors.danger : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!_started || widget.spec.controls) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 96,
                  child: _started && widget.spec.controls
                      ? NeonButton(
                          label: '+ 1 min',
                          variant: NeonVariant.ghost,
                          height: 40,
                          fontSize: 12,
                          onPressed: _addMinute,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                _RoundPlayButton(
                  running: _running,
                  onPressed: _started ? _toggleRunning : _start,
                ),
                const SizedBox(width: 112),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Round start / pause / resume button under the [CountdownClock] ring.
class _RoundPlayButton extends StatelessWidget {
  const _RoundPlayButton({required this.running, required this.onPressed});

  final bool running;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: running ? 'Pause' : 'Start',
      child: Pressable(
        onTap: onPressed,
        shape: BoxShape.circle,
        width: 60,
        height: 60,
        color: running ? AppColors.surfaceHigh : AppColors.primary,
        child: Icon(
          running ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 32,
          color: running ? AppColors.text : AppColors.onAccent,
        ),
      ),
    );
  }
}

/// Machines that went offline, with their role revealed.
class DownList extends StatelessWidget {
  const DownList({super.key, required this.entries, this.compact = false});

  final List<DownEntry> entries;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.danger.withValues(alpha: .45)),
      ),
      child: entries.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Quiet night',
                      style: AppText.body(
                        compact ? 15 : 17,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    'No machine offline',
                    style: AppText.body(13, color: AppColors.textSoft),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.danger.withValues(alpha: .2),
                    ),
                  _DownRow(entry: entries[i], compact: compact),
                ],
              ],
            ),
    );
  }
}

class _DownRow extends StatelessWidget {
  const _DownRow({required this.entry, required this.compact});

  final DownEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.team(entry.team);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 10 : 14,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(compact ? 15 : 17, weight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: c.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: c.withValues(alpha: .5)),
              ),
              child: Text(
                entry.role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(13, weight: FontWeight.w600, color: c),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResultRow extends StatelessWidget {
  const ResultRow({super.key, required this.line});

  final ResultLine line;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [
        TeamPerson(line.team),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            line.text,
            style: AppText.body(14, weight: FontWeight.w600, height: 1.35),
          ),
        ),
      ],
    ),
  );
}

/// Beginner help: what the Narrator does at this step. Not read out loud.
class TipCard extends StatelessWidget {
  const TipCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 2),
        child: Icon(
          Icons.lightbulb_outline_rounded,
          size: 16,
          color: AppColors.secondarySoft,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Do  ',
                style: AppText.body(
                  14,
                  weight: FontWeight.w700,
                  color: AppColors.secondarySoft,
                ),
              ),
              TextSpan(text: text),
            ],
          ),
          style: AppText.body(
            14,
            weight: FontWeight.w400,
            color: AppColors.muted,
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}

/// Narrator-only information, never read out loud.
class SecretCard extends StatelessWidget {
  const SecretCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.primary.withValues(alpha: .5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Lbl('Narrator only', color: AppColors.primarySoft),
        const SizedBox(height: 6),
        Text(text, style: AppText.body(14, height: 1.4)),
      ],
    ),
  );
}

class BannerCard extends StatelessWidget {
  const BannerCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.danger.withValues(alpha: .4)),
    ),
    child: Text(
      text,
      style: AppText.body(
        14,
        weight: FontWeight.w600,
        color: AppColors.dangerSoft,
      ),
    ),
  );
}
