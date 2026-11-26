import 'dart:async';
import '../i18n.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../game/card_code.dart';
import '../game/models.dart';
import '../game/setup_controller.dart';
import '../theme/app_theme.dart';
import 'widgets.dart';

/// The Narrator goes around the table in seating order and scans the card in
/// front of each player. Every scan gives that player the card's role, then
/// moves on to the next player without a role.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.setup, this.startAt});

  final SetupController setup;

  /// Player to scan first. Defaults to the first player without a role.
  final int? startAt;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

enum _Tone { info, ok, error }

class _ScanScreenState extends State<ScanScreen> {
  final _scanner = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
  );

  late int _player = widget.startAt ?? widget.setup.nextUnassigned ?? 0;
  String _message = tr('Point the camera at the QR code on the card.', 'Pointez la caméra vers le QR code de la carte.');
  _Tone _tone = _Tone.info;
  int _flash = 0;

  /// Ignore the camera briefly after a scan so that one card is not read twice.
  DateTime _quietUntil = DateTime.fromMillisecondsSinceEpoch(0);
  String? _lastRaw;
  DateTime _lastRawAt = DateTime.fromMillisecondsSinceEpoch(0);

  SetupController get _setup => widget.setup;

  @override
  void dispose() {
    unawaited(_scanner.dispose());
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final now = DateTime.now();
    if (now.isBefore(_quietUntil)) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null, orElse: () => null);
    if (raw == null) return;
    // The same code held in front of the camera: answer once only.
    if (raw == _lastRaw && now.difference(_lastRawAt) < const Duration(seconds: 2)) {
      _lastRawAt = now;
      return;
    }
    _lastRaw = raw;
    _lastRawAt = now;

    final card = parseCardCode(raw);
    if (card == null) {
      _say(tr('This QR code is not an Insider Threat card.', "Ce QR code n'est pas une carte Insider Threat."), _Tone.error);
      HapticFeedback.heavyImpact();
      return;
    }

    final player = _player;
    final result = _setup.assignCard(player, card);
    final name = _setup.displayName(player);
    switch (result.outcome) {
      case ScanOutcome.assigned:
        HapticFeedback.mediumImpact();
        _quietUntil = now.add(const Duration(milliseconds: 1200));
        final next = _setup.nextUnassigned;
        setState(() {
          _flash++;
          _message = '$name → ${card.role.info.name}';
          _tone = _Tone.ok;
          if (next != null) _player = next;
        });
      case ScanOutcome.sameCard:
        _say(tr('$name already has this card.', '$name a déjà cette carte.'), _Tone.info);
      case ScanOutcome.cardUsed:
        HapticFeedback.heavyImpact();
        _say(
          tr('${card.label} was already scanned for ${_setup.displayName(result.other!)}.',
              '${card.label} a déjà été scannée pour ${_setup.displayName(result.other!)}.'),
          _Tone.error,
        );
      case ScanOutcome.roleTaken:
        HapticFeedback.heavyImpact();
        _say(
          tr('${_setup.displayName(result.other!)} already has the ${card.role.info.name}. Change their role first.',
              "${_setup.displayName(result.other!)} a déjà la carte ${card.role.info.name}. Changez d'abord son rôle."),
          _Tone.error,
        );
    }
  }

  void _say(String text, _Tone tone) {
    if (!mounted) return;
    setState(() {
      _message = text;
      _tone = tone;
    });
  }

  void _select(int i) => setState(() {
        _player = i;
        _message = tr('Scan the card of ${_setup.displayName(i)}.', 'Scannez la carte de ${_setup.displayName(i)}.');
        _tone = _Tone.info;
      });

  void _skip() {
    final n = _setup.count;
    for (var k = 1; k <= n; k++) {
      final i = (_player + k) % n;
      if (_setup.roles[i] == null) {
        _select(i);
        return;
      }
    }
    _select((_player + 1) % n);
  }

  @override
  Widget build(BuildContext context) {
    return NeonBackground(
      mood: Mood.night,
      child: ListenableBuilder(
        listenable: _setup,
        builder: (context, _) {
          final done = _setup.nextUnassigned == null;
          final role = _setup.roles[_player];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(tr('‹ Setup', '‹ Préparation'),
                          style: AppText.body(15, color: AppColors.muted)),
                    ),
                    const Spacer(),
                    TagChip(tr('${_setup.assigned} / ${_setup.count} roles', '${_setup.assigned} / ${_setup.count} rôles')),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  children: [
                    Lbl(tr('Seat ${_player + 1} · card of', 'Place ${_player + 1} · carte de')),
                    const SizedBox(height: 4),
                    Text(
                      _setup.displayName(_player).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.ui(32, weight: FontWeight.w700, height: 1.05),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (role != null) ...[
                          TeamPerson(role.info.team),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          role == null ? tr('No role yet', 'Pas encore de rôle') : tr('Now: ${role.info.name}', 'Actuel : ${role.info.name}'),
                          style: AppText.body(15, color: AppColors.textSoft),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _Viewfinder(
                      scanner: _scanner,
                      onDetect: _onDetect,
                      flash: _flash,
                    ),
                    const SizedBox(height: 12),
                    _Feedback(text: _message, tone: _tone),
                    const SizedBox(height: 16),
                    Lbl(tr('Tap a player to scan their card', 'Touchez un joueur pour scanner sa carte')),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < _setup.count; i++)
                          _SeatChip(
                            name: _setup.displayName(i),
                            role: _setup.roles[i],
                            scanned: _setup.cards[i] != null,
                            current: i == _player,
                            onTap: () => _select(i),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: NeonButton(
                        label: tr('Skip', 'Passer'),
                        variant: NeonVariant.ghost,
                        onPressed: done ? null : _skip,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: NeonButton(
                        label: done ? tr('All cards scanned', 'Toutes les cartes scannées') : tr('Done', 'Terminé'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({
    required this.scanner,
    required this.onDetect,
    required this.flash,
  });

  final MobileScannerController scanner;
  final void Function(BarcodeCapture) onDetect;
  final int flash;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.15,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bg,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: scanner,
                onDetect: onDetect,
                errorBuilder: (context, error) => _CameraError(error: error),
              ),
              const IgnorePointer(child: _Corners()),
              // Brief flash when a card is accepted.
              IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(flash),
                  tween: Tween(begin: flash == 0 ? 0 : .45, end: 0),
                  duration: const Duration(milliseconds: 450),
                  builder: (_, v, _) =>
                      ColoredBox(color: AppColors.secondarySoft.withValues(alpha: v)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Corners extends StatelessWidget {
  const _Corners();

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: AppColors.secondarySoft, width: 3);
    const r = Radius.circular(10);
    Widget corner(Alignment a, Border b, BorderRadius br) => Align(
          alignment: a,
          child: Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: b, borderRadius: br),
          ),
        );
    return Stack(
      children: [
        corner(Alignment.topLeft, const Border(top: side, left: side),
            const BorderRadius.only(topLeft: r)),
        corner(Alignment.topRight, const Border(top: side, right: side),
            const BorderRadius.only(topRight: r)),
        corner(Alignment.bottomLeft, const Border(bottom: side, left: side),
            const BorderRadius.only(bottomLeft: r)),
        corner(Alignment.bottomRight, const Border(bottom: side, right: side),
            const BorderRadius.only(bottomRight: r)),
      ],
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final text = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        tr('Camera access is off. Allow it in the phone settings, or pick roles by hand in the setup.',
            "L'accès à la caméra est désactivé. Autorisez-le dans les réglages du téléphone, ou choisissez les rôles à la main."),
      MobileScannerErrorCode.unsupported =>
        tr('No camera available on this device. Pick roles by hand in the setup.',
            "Aucune caméra sur cet appareil. Choisissez les rôles à la main dans la préparation."),
      _ => tr('The camera could not start. Pick roles by hand in the setup.',
          "La caméra n'a pas pu démarrer. Choisissez les rôles à la main dans la préparation."),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined, color: AppColors.muted, size: 32),
            const SizedBox(height: 10),
            Text(text,
                textAlign: TextAlign.center,
                style: AppText.body(14, color: AppColors.textSoft, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.text, required this.tone});

  final String text;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _Tone.info => AppColors.secondary,
      _Tone.ok => AppColors.primary,
      _Tone.error => AppColors.danger,
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .5)),
        ),
        child: Text(
          text,
          style: AppText.body(15,
              weight: FontWeight.w600,
              color: tone == _Tone.error ? AppColors.dangerSoft : AppColors.text),
        ),
      ),
    );
  }
}

class _SeatChip extends StatelessWidget {
  const _SeatChip({
    required this.name,
    required this.role,
    required this.scanned,
    required this.current,
    required this.onTap,
  });

  final String name;
  final RoleId? role;
  final bool scanned;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Semantics(
      button: true,
      selected: current,
      label: '$name, ${role == null ? tr('no role', 'pas de rôle') : role!.info.name}',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: current
                ? AppColors.primary.withValues(alpha: .18)
                : AppColors.surface,
            borderRadius: radius,
            border: Border.all(color: current ? AppColors.primary : AppColors.line),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ExcludeSemantics(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, maxWidth: 160),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (role != null)
                        TeamPerson(role!.info.team)
                      else
                        const Icon(Icons.person, size: 18, color: AppColors.muted),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(14, weight: FontWeight.w600),
                        ),
                      ),
                      if (scanned) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.qr_code_2, size: 14, color: AppColors.muted),
                      ],
                    ],
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
