/// Full-screen role card reveal: the Narrator turns the phone towards a player
/// (Threat Hunter) instead of hunting for the physical card. Nothing else is
/// on screen, so the picker's team colours stay hidden.
library;

import 'dart:math';
import '../i18n.dart';

import 'package:flutter/material.dart';

import '../game/guide_step.dart';
import '../theme/app_theme.dart';
import 'event_draw/event_card_faces.dart';
import 'event_draw/sfx.dart';
import 'role_card_face.dart';
import 'widgets.dart';

Future<void> showRoleReveal(
  BuildContext context, {
  required String viewer,
  required List<RevealCard> cards,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, anim, _) => FadeTransition(
        opacity: anim,
        child: _RoleRevealScreen(viewer: viewer, cards: cards),
      ),
    ),
  );
}

class _RoleRevealScreen extends StatefulWidget {
  const _RoleRevealScreen({required this.viewer, required this.cards});

  final String viewer;
  final List<RevealCard> cards;

  @override
  State<_RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<_RoleRevealScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  int _index = 0;
  bool _flipSoundPlayed = false;

  @override
  void initState() {
    super.initState();
    _anim.addListener(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _start() {
    if (!mounted) return;
    _flipSoundPlayed = false;
    if (MediaQuery.disableAnimationsOf(context)) {
      _anim.value = 1;
    } else {
      _anim.forward(from: 0);
    }
  }

  void _onTick() {
    // Sound when the card starts turning over.
    if (!_flipSoundPlayed && _anim.value >= _flipStart) {
      _flipSoundPlayed = true;
      Sfx.instance.play(SfxId.flip, volume: .6);
    }
  }

  void _next() {
    if (_index < widget.cards.length - 1) {
      setState(() => _index++);
      _start();
    } else {
      Navigator.of(context).pop();
    }
  }

  static const _flipStart = .38;

  @override
  Widget build(BuildContext context) {
    final card = widget.cards[_index];
    final many = widget.cards.length > 1;
    final last = _index == widget.cards.length - 1;
    final label = Lbl(many
        ? tr('For ${widget.viewer}  ·  Card ${_index + 1} / ${widget.cards.length}',
            'Pour ${widget.viewer}  ·  Carte ${_index + 1} / ${widget.cards.length}')
        : tr('For ${widget.viewer}', 'Pour ${widget.viewer}'));
    final close = IconButton(
      tooltip: tr('Close', 'Fermer'),
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.close_rounded, color: AppColors.textSoft),
    );
    final cardArea = LayoutBuilder(
      builder: (context, box) {
        final width = min(box.maxWidth * .92, box.maxHeight * .94 * kCardRatio);
        return Center(
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) =>
                _FlippingCard(t: _anim.value, card: card, width: width),
          ),
        );
      },
    );
    final action = AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => IgnorePointer(
        ignoring: _anim.value < 1,
        child: Opacity(opacity: interval(_anim.value, .85, 1), child: child),
      ),
      child: NeonButton(
        label: last ? tr('Done', 'Terminé') : tr('Next card', 'Carte suivante'),
        variant: last ? NeonVariant.ghost : NeonVariant.primary,
        onPressed: _next,
      ),
    );

    final landscape = isShortLandscape(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, landscape ? 8 : 12, 20, landscape ? 8 : 16),
          child: landscape
              // Phone held sideways: the card takes the full height, the
              // controls sit in a rail on the right.
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cardArea),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [Expanded(child: label), close]),
                          const Spacer(),
                          action,
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [Expanded(child: label), close]),
                    Expanded(child: cardArea),
                    const SizedBox(height: 12),
                    action,
                  ],
                ),
        ),
      ),
    );
  }
}

/// [t] 0..1: the card comes in face down, then turns over to the left.
class _FlippingCard extends StatelessWidget {
  const _FlippingCard({required this.t, required this.card, required this.width});

  final double t;
  final RevealCard card;
  final double width;

  @override
  Widget build(BuildContext context) {
    final enter = interval(t, 0, .3);
    final flip = interval(t, _RoleRevealScreenState._flipStart, 1, Curves.easeInOutCubic);
    final showFront = flip >= .5;
    final lift = 1 + .08 * sin(pi * flip);
    final scale = (.86 + .14 * enter) * lift;
    return Opacity(
      opacity: enter,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, .0012)
          ..translateByDouble(0, 30 * (1 - enter), 0, 1)
          ..rotateY(-pi * flip)
          ..scaleByDouble(scale, scale, 1, 1),
        child: showFront
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(pi),
                child: _RoleFront(card: card, width: width),
              )
            : _RoleBack(width: width),
      ),
    );
  }
}

/// Card front at the reveal size.
class _RoleFront extends StatelessWidget {
  const _RoleFront({required this.card, required this.width});

  final RevealCard card;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: width / kCardRatio,
        child: RoleCardFace(info: card.info, footer: card.name, glow: true),
      );
}

class _RoleBack extends StatelessWidget {
  const _RoleBack({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: width / kCardRatio,
        child: const RoleCardBack(),
      );
}
