import 'dart:math';
import '../i18n.dart';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/game_controller.dart';
import '../game/models.dart';
import '../theme/app_theme.dart';
import '../theme/palette.dart';
import 'event_draw/glitch.dart';
import 'event_draw/sfx.dart';
import 'widgets.dart';

/// Background effect of each ending.
enum _Fx { shield, breach, spotlight, tunnel, outage }

/// Everything that changes from one ending to another.
class _Ending {
  const _Ending({
    required this.label,
    required this.line1,
    required this.line2,
    required this.say,
    required this.tag,
    required this.icon,
    required this.color,
    required this.colors,
    required this.fx,
    required this.sfx,
  });

  final String label;
  final String line1;
  final String line2;
  final String say;

  /// Terminal line typed under the title.
  final String tag;
  final IconData icon;
  final Color color;

  /// Gradient of the big title.
  final List<Color> colors;
  final _Fx fx;
  final SfxId sfx;

  static _Ending of(Winner w) => switch (w) {
        Winner.blue => _Ending(
            label: tr('Blue Team wins', 'La Blue Team gagne'),
            line1: tr('Network', 'Réseau'),
            line2: tr('Secured', 'Sécurisé'),
            say: tr('All attackers have been quarantined. Network secured. The Blue Team wins!',
                'Tous les attaquants ont été mis en quarantaine. Réseau sécurisé. La Blue Team gagne !'),
            tag: '> threat_level: 0 // all attackers quarantined',
            icon: Icons.verified_user_rounded,
            color: AppColors.teamBlue,
            colors: [Picton.c100, Picton.c300, Picton.c500],
            fx: _Fx.shield,
            sfx: SfxId.revealBlue,
          ),
        Winner.red => _Ending(
            label: tr('Red Team wins', 'La Red Team gagne'),
            line1: tr('Network', 'Réseau'),
            line2: tr('Breached', 'Compromis'),
            say: tr('The last defender has fallen. Network breached. The Red Team wins!',
                'Le dernier défenseur est tombé. Réseau compromis. La Red Team gagne !'),
            tag: '> root access granted // defenders: 0',
            icon: Icons.gpp_bad_rounded,
            color: AppColors.teamRed,
            colors: [Signal.c200, Signal.c400, Signal.c500],
            fx: _Fx.breach,
            sfx: SfxId.revealRed,
          ),
        Winner.purple => _Ending(
            label: tr('Purple Team wins', 'La Purple Team gagne'),
            line1: tr('Last machine', 'Dernière machine'),
            line2: tr('Standing', 'Debout'),
            say: tr('Only one machine is left on the network. The double agent wins. The Purple Team wins!',
                "Il ne reste qu'une machine sur le réseau. L'agent double gagne. La Purple Team gagne !"),
            tag: '> double agent identified // too late',
            icon: Icons.theater_comedy_rounded,
            color: AppColors.teamPurple,
            colors: [Blush.c200, Violet.c400, Blush.c500],
            fx: _Fx.spotlight,
            sfx: SfxId.revealChaos,
          ),
        Winner.vpn => _Ending(
            label: tr('VPN Tunnel wins', 'Le VPN Tunnel gagne'),
            line1: 'Tunnel',
            line2: tr('Intact', 'Intact'),
            say: tr('The last two machines are linked by a VPN tunnel. The VPN Tunnel wins!',
                'Les deux dernières machines sont reliées par un tunnel VPN. Le VPN Tunnel gagne !'),
            tag: '> encrypted link up // 2 peers online',
            icon: Icons.vpn_lock_rounded,
            color: AppColors.primary,
            colors: [Lime.c200, Lime.c400, Picton.c300],
            fx: _Fx.tunnel,
            sfx: SfxId.revealChaos,
          ),
        Winner.outage => _Ending(
            label: tr('Nobody wins', 'Personne ne gagne'),
            line1: tr('Total', 'Panne'),
            line2: tr('Outage', 'Totale'),
            say: tr('Every machine went down at the same time. Total outage. Nobody wins.',
                'Toutes les machines sont tombées en même temps. Panne totale. Personne ne gagne.'),
            tag: '> no signal // 0 machines online',
            icon: Icons.power_off_rounded,
            color: Cod.c300,
            colors: [Cod.c50, Cod.c300, Cod.c500],
            fx: _Fx.outage,
            sfx: SfxId.out,
          ),
      };
}

/// Fraction of [t] between [a] and [b], clamped to 0..1.
double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

class EndScreen extends StatefulWidget {
  const EndScreen({super.key, required this.game, required this.onNewGame});

  final GameController game;
  final VoidCallback onNewGame;

  @override
  State<EndScreen> createState() => _EndScreenState();
}

class _EndScreenState extends State<EndScreen> with TickerProviderStateMixin {
  // Moments of the intro, as fractions of [_intro].
  static const _slam = 0.36;
  static const _impact = 0.46;

  // A getter, not a cached value: the texts follow the language setting.
  _Ending get _end => _Ending.of(widget.game.winner!);
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  /// Drives the never-ending background effects.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  final _rnd = Random();
  bool _hit = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
      return;
    }
    if (_end.fx == _Fx.breach || _end.fx == _Fx.outage) {
      Sfx.instance.play(SfxId.glitch, volume: .7);
    }
    _intro.addListener(_onIntro);
    _intro.forward();
    _loop.repeat();
  }

  void _onIntro() {
    if (!_hit && _intro.value >= _impact) {
      _hit = true;
      Sfx.instance.play(_end.sfx);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  bool _won(Player p) => switch (widget.game.winner!) {
        Winner.blue => p.team == Team.blue,
        Winner.red => p.team == Team.red,
        Winner.purple => p.team == Team.purple,
        Winner.vpn => p.alive,
        Winner.outage => false,
      };

  /// Screen shake after the impact, stronger for the bad endings.
  Offset _shake(double t) {
    final p = _seg(t, _impact, _impact + .2);
    if (p <= 0 || p >= 1) return Offset.zero;
    final amp = (_end.fx == _Fx.shield || _end.fx == _Fx.tunnel ? 6.0 : 12.0) *
        (1 - p);
    return Offset(sin(p * 70) * amp, cos(p * 55) * amp * .6);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final players = [...game.players]
      ..sort((a, b) => (_won(b) ? 1 : 0) - (_won(a) ? 1 : 0));

    // Full bleed: the effects run under the status bar too, so the top of
    // the screen blends in instead of showing the NeonBackground glow.
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _loop]),
        builder: (context, _) {
          final t = _intro.value;
          final flash = t < _impact ? 0.0 : 1 - _seg(t, _impact, _impact + .14);
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _BackdropPainter(
                      fx: _end.fx,
                      color: _end.color,
                      intro: t,
                      loop: _loop.value,
                      impact: _impact,
                      focusY: top + 136,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Transform.translate(
                      offset: _shake(t),
                      child: _content(t, players),
                    ),
                  ),
                ),
              ),
              // Impact flash.
              if (flash > 0)
                IgnorePointer(
                  child: ColoredBox(
                    color: Color.lerp(Colors.white, _end.color, .35)!
                        .withValues(alpha: flash * .75),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _content(double t, List<Player> players) {
    final game = widget.game;
    final alive = game.players.where((p) => p.alive).length;
    final total = game.players.length;
    final cols = isShortLandscape(context) ? 3 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: _seg(t, 0, .12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TagChip(tr('Game over', 'Partie terminée')),
                Lbl(tr('Day ', 'Jour ') + game.night.toString().padLeft(2, '0')),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            clipBehavior: Clip.none,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              _Emblem(
                ending: _end,
                intro: t,
                loop: _loop.value,
              ),
              const SizedBox(height: 6),
              _title(t),
              const SizedBox(height: 10),
              _tagLine(t),
              const SizedBox(height: 18),
              _reveal(
                t,
                .62,
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: tr('Machines online', 'Machines en ligne'),
                        value:
                            '${(alive * _seg(t, .62, .8)).round()}/$total',
                        color: _end.color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Stat(
                        label: tr('Days survived', 'Jours tenus'),
                        value:
                            '${(game.night * _seg(t, .62, .8)).round()}'.padLeft(2, '0'),
                        color: _end.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (t >= .7) _reveal(t, .7, SayCard(text: _end.say)),
              const SizedBox(height: 16),
              _reveal(t, .76, Lbl(tr('Roles revealed', 'Rôles révélés'))),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisExtent: 56,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: players.length,
                itemBuilder: (_, i) {
                  final start = (.78 + i * .025).clamp(0.0, .96);
                  return _reveal(
                    t,
                    start,
                    _RoleCell(
                      player: players[i],
                      won: _won(players[i]),
                      glow: _end.color,
                      pulse: _loop.value,
                    ),
                    span: .06,
                  );
                },
              ),
            ],
          ),
        ),
        Opacity(
          opacity: _seg(t, .9, 1),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: NeonButton(
              label: tr('New game', 'Nouvelle partie'),
              onPressed: t > .9 ? widget.onNewGame : null,
            ),
          ),
        ),
      ],
    );
  }

  /// Fades and slides [child] up from [start].
  Widget _reveal(double t, double start, Widget child, {double span = .12}) {
    final p = Curves.easeOutCubic.transform(_seg(t, start, start + span));
    return Opacity(
      opacity: p,
      child: Transform.translate(offset: Offset(0, (1 - p) * 24), child: child),
    );
  }

  Widget _title(double t) {
    // Line 1 slides in from the left.
    final p1 = Curves.easeOutCubic.transform(_seg(t, .18, .34));
    // Line 2 slams in: huge and transparent, down to its size.
    final p2 = _seg(t, _slam, _impact);
    final scale = 1 + 2.4 * pow(1 - p2, 3);
    final line2Opacity = Curves.easeIn.transform(p2);

    // Red glitches in bursts; outage flickers like a dying screen.
    final loop = _loop.value;
    final burst = t >= _impact && t < _impact + .25 ||
        (loop * 5) % 1 < .08 ||
        (loop * 3 + .4) % 1 < .04;
    final glitchy = _end.fx == _Fx.breach || _end.fx == _Fx.spotlight;
    final flicker = _end.fx == _Fx.outage && t >= 1 && _rnd.nextDouble() < .06
        ? .25
        : 1.0;

    final big = AppText.ui(92, height: .9, spacing: 1);
    Widget word(Color? color) => Text(
          _end.line2.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          style: color == null ? big : big.copyWith(color: color),
        );

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: _end.colors,
    );
    Widget line2 = Stack(
      alignment: Alignment.center,
      children: [
        // Neon glow.
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Opacity(
            opacity: .5 + .3 * sin(loop * 2 * pi * 2).abs(),
            child: word(_end.color),
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: gradient.createShader,
          child: word(null),
        ),
        if (glitchy && burst) ...[
          GlitchLayer(
            slice: GlitchSlice.random(_rnd),
            tint: Picton.c400,
            child: word(AppColors.text),
          ),
          GlitchLayer(
            slice: GlitchSlice.random(_rnd),
            tint: Signal.c400,
            child: word(AppColors.text),
          ),
        ],
      ],
    );

    return Column(
      children: [
        Opacity(
          opacity: p1,
          child: Transform.translate(
            offset: Offset(-60 * (1 - p1), 0),
            child: Text(
              _end.line1.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppText.ui(34, color: AppColors.textSoft, spacing: 6),
            ),
          ),
        ),
        Opacity(
          opacity: line2Opacity * flicker,
          child: Transform.scale(
            scale: scale.toDouble(),
            child: FittedBox(fit: BoxFit.scaleDown, child: line2),
          ),
        ),
      ],
    );
  }

  Widget _tagLine(double t) {
    final p = _seg(t, .55, .78);
    final text = _end.tag;
    final n = (text.length * p).round();
    final caret = (_loop.value * 12).floor().isEven ? '_' : ' ';
    return Opacity(
      opacity: p > 0 ? 1 : 0,
      child: Text(
        '${text.substring(0, n)}$caret',
        textAlign: TextAlign.center,
        style: AppText.mono(13, color: _end.color, spacing: .5),
      ),
    );
  }
}

/// The big icon in its spinning rings, popping in with a bounce.
class _Emblem extends StatelessWidget {
  const _Emblem({required this.ending, required this.intro, required this.loop});

  final _Ending ending;
  final double intro;
  final double loop;

  @override
  Widget build(BuildContext context) {
    final p = _seg(intro, .04, .34);
    final scale = Curves.elasticOut.transform(p);
    final c = ending.color;
    final breathe = 1 + .05 * sin(loop * 2 * pi * 3);
    return SizedBox(
      height: 170,
      child: Center(
        child: Transform.scale(
          scale: scale * breathe,
          child: Transform.rotate(
            angle: (1 - p) * -.6,
            child: SizedBox(
              width: 150,
              height: 150,
              child: CustomPaint(
                painter: _RingsPainter(color: c, loop: loop, fx: ending.fx),
                child: Center(
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.withValues(alpha: .14),
                      border: Border.all(color: c, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: c.withValues(alpha: .55),
                          blurRadius: 36,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(ending.icon, size: 52, color: c),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.color, required this.loop, required this.fx});

  final Color color;
  final double loop;
  final _Fx fx;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final a = loop * 2 * pi;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Outer dashed ring, turning one way.
    paint
      ..strokeWidth = 3
      ..color = color.withValues(alpha: .85);
    const dashes = 12;
    for (var i = 0; i < dashes; i++) {
      final start = a * 2 + i * 2 * pi / dashes;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r - 4), start,
          pi / dashes * 1.1, false, paint);
    }
    // Inner arcs, turning the other way.
    paint
      ..strokeWidth = 2
      ..color = color.withValues(alpha: .5);
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r - 16),
          -a * 3 + i * 2 * pi / 3, pi / 2, false, paint);
    }
    // Red and outage: a warning tick that blinks.
    if ((fx == _Fx.breach || fx == _Fx.outage) && (loop * 8).floor().isEven) {
      canvas.drawCircle(
        c + Offset(cos(-a * 3), sin(-a * 3)) * (r - 16),
        4,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.loop != loop;
}

/// Full-screen effect behind the content.
class _BackdropPainter extends CustomPainter {
  _BackdropPainter({
    required this.fx,
    required this.color,
    required this.intro,
    required this.loop,
    required this.impact,
    required this.focusY,
  });

  final _Fx fx;
  final Color color;
  final double intro;
  final double loop;
  final double impact;

  /// Height of the emblem's centre, where the rings start.
  final double focusY;

  /// Fixed seed so streaks and stars keep their place from frame to frame.
  static final _seeds = List.generate(
    60,
    (i) => Random(i * 7919).nextDouble(),
  );

  double _s(int i) => _seeds[i % _seeds.length];

  @override
  void paint(Canvas canvas, Size size) {
    // The emblem sits around here.
    final focus = Offset(size.width / 2, focusY);
    _topGlow(canvas, size);
    switch (fx) {
      case _Fx.shield:
        _grid(canvas, size);
        _scanBeam(canvas, size);
        _shockwaves(canvas, size, focus);
      case _Fx.breach:
        _rain(canvas, size);
        _hazard(canvas, size);
        _shockwaves(canvas, size, focus);
        // Alarm: the whole screen pulses red.
        final pulse = (sin(loop * 2 * pi * 4) + 1) / 2;
        canvas.drawRect(
          Offset.zero & size,
          Paint()..color = color.withValues(alpha: .05 + .07 * pulse),
        );
      case _Fx.spotlight:
        _rays(canvas, size, focus);
        _shockwaves(canvas, size, focus);
      case _Fx.tunnel:
        _tunnel(canvas, size, focus);
        _shockwaves(canvas, size, focus);
      case _Fx.outage:
        _static(canvas, size);
        _crtOff(canvas, size);
    }
    _vignette(canvas, size);
  }

  /// Soft glow of the winner's colour from the top edge.
  void _topGlow(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -1.1),
          radius: 1.1,
          colors: [color.withValues(alpha: .22), color.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  void _grid(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: .07)
      ..strokeWidth = 1;
    const step = 28.0;
    final dy = (loop * step * 6) % step;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = dy - step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  void _scanBeam(Canvas canvas, Size size) {
    final y = ((loop * 2) % 1) * (size.height + 200) - 100;
    final rect = Rect.fromLTWH(0, y - 80, size.width, 100);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0), color.withValues(alpha: .16)],
        ).createShader(rect),
    );
    canvas.drawLine(
      Offset(0, y + 20),
      Offset(size.width, y + 20),
      Paint()
        ..color = color.withValues(alpha: .5)
        ..strokeWidth = 1.5,
    );
  }

  /// Rings blasting out of the emblem at the impact, then softer pulses.
  void _shockwaves(Canvas canvas, Size size, Offset c) {
    final maxR = size.longestSide * 1.1;
    final p = Paint()..style = PaintingStyle.stroke;
    final blast = _seg(intro, impact, impact + .35);
    if (blast > 0 && blast < 1) {
      for (var i = 0; i < 3; i++) {
        final q = (blast - i * .12).clamp(0.0, 1.0);
        if (q <= 0) continue;
        p
          ..strokeWidth = 10 * (1 - q) + 1
          ..color = color.withValues(alpha: .7 * (1 - q));
        canvas.drawCircle(c, Curves.easeOutCubic.transform(q) * maxR, p);
      }
    }
    if (intro >= 1) {
      for (var i = 0; i < 2; i++) {
        final q = (loop * 2 + i / 2) % 1;
        p
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: .22 * (1 - q));
        canvas.drawCircle(c, 70 + q * size.width * .7, p);
      }
    }
  }

  /// Falling red code streaks.
  void _rain(Canvas canvas, Size size) {
    final p = Paint();
    const n = 34;
    for (var i = 0; i < n; i++) {
      final x = _s(i) * size.width;
      final speed = .6 + _s(i + 17) * 1.4;
      final len = 40 + _s(i + 31) * 120;
      final y = ((loop * speed * 3 + _s(i + 5)) % 1) * (size.height + len) - len;
      final rect = Rect.fromLTWH(x, y, 2, len);
      p.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0), color.withValues(alpha: .45)],
      ).createShader(rect);
      canvas.drawRect(rect, p);
      canvas.drawRect(
        Rect.fromLTWH(x - 1, y + len - 3, 4, 4),
        Paint()..color = Signal.c200.withValues(alpha: .8),
      );
    }
  }

  /// Scrolling hazard tape at the top and the bottom.
  void _hazard(Canvas canvas, Size size) {
    const h = 14.0;
    final shift = (loop * 120) % 28;
    for (final y in [0.0, size.height - h]) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, y, size.width, h));
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, h),
          Paint()..color = Cod.c950);
      final stripe = Paint()..color = color.withValues(alpha: .8);
      for (var x = -28.0 + shift; x < size.width + 28; x += 28) {
        canvas.drawPath(
          Path()
            ..moveTo(x, y + h)
            ..lineTo(x + 14, y)
            ..lineTo(x + 24, y)
            ..lineTo(x + 10, y + h)
            ..close(),
          stripe,
        );
      }
      canvas.restore();
    }
  }

  /// Turning violet light rays.
  void _rays(Canvas canvas, Size size, Offset c) {
    final r = size.longestSide * 1.2;
    const n = 14;
    final a0 = loop * 2 * pi * .5;
    final reveal = _seg(intro, impact - .1, impact + .2);
    for (var i = 0; i < n; i++) {
      final a = a0 + i * 2 * pi / n;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + cos(a) * r, c.dy + sin(a) * r)
        ..lineTo(c.dx + cos(a + .12) * r, c.dy + sin(a + .12) * r)
        ..close();
      final col = i.isEven ? color : Blush.c400;
      canvas.drawPath(
        path,
        Paint()
          ..shader = RadialGradient(
            colors: [col.withValues(alpha: .28 * reveal), col.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: c, radius: r * .7)),
      );
    }
  }

  /// Rounded frames rushing towards the viewer.
  void _tunnel(Canvas canvas, Size size, Offset c) {
    const n = 9;
    final p = Paint()..style = PaintingStyle.stroke;
    for (var i = 0; i < n; i++) {
      final q = (loop * 1.5 + i / n) % 1;
      final z = pow(q, 2.2).toDouble();
      final w = 30 + z * size.width * 2.4;
      final h = 22 + z * size.height * 1.6;
      p
        ..strokeWidth = 1 + z * 6
        ..color = Color.lerp(Picton.c400, color, q)!
            .withValues(alpha: (.55 * (1 - q)) * _seg(intro, .2, .5));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: w, height: h),
          Radius.circular(12 + z * 60),
        ),
        p,
      );
    }
  }

  /// TV static, thick at first and fading to a few specks.
  void _static(Canvas canvas, Size size) {
    final rnd = Random();
    final density = intro < 1 ? 1 - _seg(intro, impact, 1) * .85 : .15;
    final n = (420 * density).round();
    final p = Paint();
    for (var i = 0; i < n; i++) {
      final g = rnd.nextDouble();
      p.color = Color.lerp(Cod.c900, Cod.c300, g)!.withValues(alpha: .35);
      canvas.drawRect(
        Rect.fromLTWH(rnd.nextDouble() * size.width,
            rnd.nextDouble() * size.height, 2 + g * 3, 2),
        p,
      );
    }
    // Rolling interference bar.
    final y = (loop * 1.3 % 1) * size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, y, size.width, 40),
      Paint()..color = Cod.c50.withValues(alpha: .04),
    );
  }

  /// A CRT switching off: the picture collapses to a line, then a dot.
  void _crtOff(Canvas canvas, Size size) {
    final p = _seg(intro, .05, impact);
    if (p <= 0 || p >= 1) return;
    final c = size.center(Offset.zero);
    final h = size.height * pow(1 - p, 4).toDouble() + 2;
    final w = p < .8 ? size.width : size.width * (1 - _seg(p, .8, 1)) + 4;
    canvas.drawRect(
      Rect.fromCenter(center: c, width: w, height: h),
      Paint()..color = Cod.c50.withValues(alpha: .5),
    );
  }

  void _vignette(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: .9,
          colors: [Colors.transparent, Cod.c950.withValues(alpha: .7)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.loop != loop || old.intro != intro;
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: .85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Lbl(label),
            const SizedBox(height: 4),
            Text(value.toUpperCase(), style: AppText.ui(34, color: color, height: 1)),
          ],
        ),
      );
}

class _RoleCell extends StatelessWidget {
  const _RoleCell({
    required this.player,
    required this.won,
    required this.glow,
    required this.pulse,
  });

  final Player player;

  /// On the winning side: lit up.
  final bool won;
  final Color glow;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final teamColor = AppColors.team(player.team);
    final g = (sin(pulse * 2 * pi * 2) + 1) / 2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: won ? Color.lerp(AppColors.surface, glow, .12) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: won ? glow.withValues(alpha: .6 + .4 * g) : AppColors.line,
          width: won ? 1.5 : 1,
        ),
        boxShadow: won
            ? [
                BoxShadow(
                  color: glow.withValues(alpha: .15 + .2 * g),
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          TeamPerson(player.team),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    15,
                    weight: FontWeight.w600,
                    color: player.alive ? AppColors.text : AppColors.muted,
                    decoration: player.alive ? null : TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  player.role.info.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(13,
                      weight: FontWeight.w400,
                      color: won ? teamColor : AppColors.muted),
                ),
              ],
            ),
          ),
          if (won) Icon(Icons.emoji_events_rounded, size: 18, color: glow),
        ],
      ),
    );
  }
}
