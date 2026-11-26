/// The Event draw: alert, CRT power-on, glitch, 3D flip, then the card is
/// revealed. The game engine draws the card; this panel only shows it.
library;

import 'dart:async';
import '../../i18n.dart';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../game/events.dart';
import '../../theme/app_theme.dart';
import 'event_card_faces.dart';
import 'glitch.dart';
import 'sfx.dart';

class EventDrawPanel extends StatefulWidget {
  const EventDrawPanel({
    super.key,
    required this.card,
    required this.animate,
    this.onRevealed,
  });

  final EventCard card;

  /// false = show the card already revealed (it was drawn earlier today).
  final bool animate;
  final VoidCallback? onRevealed;

  @override
  State<EventDrawPanel> createState() => _EventDrawPanelState();
}

class _EventDrawPanelState extends State<EventDrawPanel>
    with TickerProviderStateMixin {
  static const _glyphs = r'!<>-_\/[]{}=+*^?#01ABCDEFX$%&';
  final _rnd = Random();

  late final AnimationController _alert = _ctrl(900);
  late final AnimationController _sweep = _ctrl(520);
  late final AnimationController _spawn = _ctrl(560);
  late final AnimationController _flip = _ctrl(620);
  late final AnimationController _reveal = _ctrl(1100);
  late final AnimationController _glow = _ctrl(900);

  List<AnimationController> get _all =>
      [_alert, _sweep, _spawn, _flip, _reveal, _glow];

  AnimationController _ctrl(int ms) =>
      AnimationController(vsync: this, duration: Duration(milliseconds: ms));

  // CRT power-on: a thin bright line that opens into the full card.
  static const _spawnCurve = Cubic(0.2, 0.8, 0.2, 1);
  static final _spawnX = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.04), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 45),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 20),
  ]);
  static final _spawnY = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0.004), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 0.004, end: 1.03), weight: 45),
    TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 20),
  ]);
  static final _spawnFlash = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0.85), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 0.85, end: 0.35), weight: 45),
    TweenSequenceItem(tween: Tween(begin: 0.35, end: 0.0), weight: 20),
  ]);
  static final _spawnOpacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 35),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
  ]);
  static final _alertOpacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.15), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.15, end: 1.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
  ]);
  static final _glowOpacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.35), weight: 60),
  ]);

  String _title = '';
  bool _busy = false;
  bool _shown = false;
  bool _reduced = false;
  bool _glitchOnFront = false;
  GlitchSlice? _pink;
  GlitchSlice? _cyan;
  Offset _jitter = Offset.zero;

  /// Bumped on every run so that an older run stops when a new one starts.
  int _run = 0;

  String get _fullTitle => widget.card.info.title.toUpperCase();

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      Sfx.instance.preload();
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    } else {
      _showRevealed();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the phone's "reduce animations" setting.
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      for (final c in _all) {
        c.duration = const Duration(milliseconds: 150);
      }
    }
  }

  @override
  void dispose() {
    _run++;
    final own = widget.card.revealSfx;
    if (own != null) Sfx.instance.fadeOut(own);
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  void _showRevealed() {
    _spawn.value = 1;
    _flip.value = 1;
    _reveal.value = 1;
    _glow.value = 1;
    _title = _fullTitle;
    _shown = true;
  }

  bool _alive(int run) => mounted && run == _run;

  Future<void> _play() async {
    if (!mounted) return;
    final run = ++_run;
    final sfx = Sfx.instance;
    setState(() {
      _busy = true;
      _shown = false;
      _title = '';
      _glitchOnFront = false;
    });
    for (final c in _all) {
      c.value = 0;
    }

    try {
      // 1. alert + scan sweep
      sfx.play(SfxId.alert);
      unawaited(_alert.forward(from: 0).orCancel.catchError((_) {}));
      if (!_reduced) await _sweep.forward(from: 0).orCancel;
      if (!_alive(run)) return;

      // 2. CRT power-on
      sfx.play(SfxId.spawn);
      await _spawn.forward(from: 0).orCancel;
      if (!_alive(run)) return;

      // 3. glitch burst on the back
      sfx.play(SfxId.glitch);
      await _glitchBurst(const Duration(milliseconds: 420), run);
      if (!_alive(run)) return;

      // 4. flip
      sfx.play(SfxId.flip);
      await _flip.forward(from: 0).orCancel;
      if (!_alive(run)) return;

      // 5. reveal: glow, decoded title, staggered blocks
      sfx.play(widget.card.revealSfx ?? widget.card.info.side.revealSfx);
      unawaited(_glow.forward(from: 0).orCancel.catchError((_) {}));
      final reveal = _reveal.forward(from: 0).orCancel;
      await _scramble(_fullTitle, const Duration(milliseconds: 650), run);
      await reveal;
      if (!_alive(run)) return;
      _glitchOnFront = true;
      await _glitchBurst(const Duration(milliseconds: 160), run);
    } on TickerCanceled {
      return; // the panel went away mid-animation
    }

    if (!_alive(run)) return;
    setState(() {
      _shown = true;
      _busy = false;
    });
    widget.onRevealed?.call();
  }

  Future<void> _glitchBurst(Duration d, int run) async {
    if (_reduced) return;
    var elapsed = Duration.zero;
    while (elapsed < d) {
      if (!_alive(run)) return;
      setState(() {
        _pink = GlitchSlice.random(_rnd);
        _cyan = GlitchSlice.random(_rnd);
        _jitter = Offset(
            (_rnd.nextDouble() - 0.5) * 6, (_rnd.nextDouble() - 0.5) * 3);
      });
      final step = Duration(milliseconds: 45 + _rnd.nextInt(30));
      await Future<void>.delayed(step);
      elapsed += step;
    }
    if (!_alive(run)) return;
    setState(() {
      _pink = null;
      _cyan = null;
      _jitter = Offset.zero;
    });
  }

  /// Random symbols that resolve, left to right, into [text].
  Future<void> _scramble(String text, Duration d, int run) async {
    if (_reduced) {
      if (_alive(run)) setState(() => _title = text);
      return;
    }
    const step = Duration(milliseconds: 30);
    var elapsed = Duration.zero;
    while (elapsed < d) {
      final p = elapsed.inMilliseconds / d.inMilliseconds;
      final solved = (p * text.length).floor().clamp(0, text.length).toInt();
      final b = StringBuffer(text.substring(0, solved));
      for (var i = solved; i < text.length; i++) {
        b.write(text[i] == ' ' ? ' ' : _glyphs[_rnd.nextInt(_glyphs.length)]);
      }
      if (!_alive(run)) return;
      setState(() => _title = b.toString());
      await Future<void>.delayed(step);
      elapsed += step;
    }
    if (_alive(run)) setState(() => _title = text);
  }

  @override
  Widget build(BuildContext context) {
    final side = widget.card.info.side;
    final accent = side.color;

    return Semantics(
      label: tr('Event of the day: ', 'Événement du jour : ') +
          '${widget.card.info.title}. ${widget.card.face.effect.replaceAll('**', '')}',
      child: LayoutBuilder(builder: (context, box) {
        final w = min(box.maxWidth * 0.78, 300.0);
        final h = w / kCardRatio;
        final stageH = h + 24;
        return ExcludeSemantics(
          child: Column(
            children: [
              SizedBox(
                height: 22,
                child: AnimatedBuilder(
                  animation: _alert,
                  builder: (_, _) => Opacity(
                    opacity: _alert.value == 0
                        ? 0
                        : _alertOpacity.transform(_alert.value),
                    child: Text(
                      tr('⚠ INCOMING EVENT', '⚠ ÉVÉNEMENT ENTRANT'),
                      style: cardMono(size: 13, color: accent, spacing: 4.5)
                          .copyWith(shadows: [Shadow(color: accent, blurRadius: 12)]),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: stageH,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // scan sweep
                    AnimatedBuilder(
                      animation: _sweep,
                      builder: (_, _) {
                        final t = Curves.easeIn.transform(_sweep.value);
                        final o = _sweep.value == 0
                            ? 0.0
                            : (t < 0.1 ? t * 10 : 1 - t);
                        return Positioned(
                          top: stageH * t,
                          left: 0,
                          right: 0,
                          child: Opacity(
                            opacity: o.clamp(0.0, 1.0).toDouble(),
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(color: accent, boxShadow: [
                                BoxShadow(color: accent, blurRadius: 18, spreadRadius: 4),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
                    _card(w, h),
                  ],
                ),
              ),
              SizedBox(
                height: 44,
                child: AnimatedOpacity(
                  opacity: _shown && !_busy ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton.icon(
                    onPressed: _shown && !_busy ? _play : null,
                    icon: const Icon(Icons.replay, size: 16, color: AppColors.muted),
                    label: Text(tr('Replay the draw', 'Rejouer le tirage'),
                        style: AppText.body(13, color: AppColors.muted)),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _card(double w, double h) {
    final side = widget.card.info.side;
    return AnimatedBuilder(
      animation: Listenable.merge([_spawn, _flip, _reveal, _glow]),
      builder: (context, _) {
        final s = _spawnCurve.transform(_spawn.value);
        final sx = _spawnX.transform(s);
        final sy = _spawnY.transform(s);
        final flash = _spawn.value == 0 ? 0.0 : _spawnFlash.transform(s);
        final opacity = _spawn.value == 0 ? 0.0 : _spawnOpacity.transform(s);

        // flip: an overshooting curve gives a small bounce at the end
        final f = const Cubic(0.6, -0.25, 0.25, 1.25).transform(_flip.value);
        final angle = pi * f;
        final bump = 1 + 0.08 * sin(pi * _flip.value);
        final showFront = angle > pi / 2;

        final back = CardBack(width: w);
        final front = CardFront(
            card: widget.card, width: w, title: _title, reveal: _reveal.value);
        final face = showFront
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(pi),
                child: front)
            : back;
        final glitchSource = _glitchOnFront ? front : back;
        final glow = _glow.value == 0 ? 0.0 : _glowOpacity.transform(_glow.value);

        return Transform.translate(
          offset: _jitter,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(max(sx, 0.0001), max(sy, 0.0001), 1),
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0).toDouble(),
              child: SizedBox(
                width: w,
                height: h,
                child: Stack(clipBehavior: Clip.none, children: [
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(angle)
                      ..scaleByDouble(bump, bump, 1.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          if (glow > 0)
                            BoxShadow(
                                color: side.color.withValues(alpha: 0.9 * glow),
                                blurRadius: 40,
                                spreadRadius: 4),
                        ],
                      ),
                      child: Stack(children: [
                        face,
                        if (glow > 0)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: side.color.withValues(alpha: glow),
                                      width: 2),
                                ),
                              ),
                            ),
                          ),
                      ]),
                    ),
                  ),
                  // RGB-split glitch slices
                  GlitchLayer(
                      slice: _pink,
                      tint: AppColors.teamRed,
                      child: glitchSource),
                  GlitchLayer(
                      slice: _cyan,
                      tint: AppColors.teamBlue,
                      child: glitchSource),
                  // white flash (CRT brightness)
                  if (flash > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: ColoredBox(
                              color: Colors.white.withValues(
                                  alpha: flash.clamp(0.0, 1.0).toDouble())),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}
