/// The character side of a role card, in the app's own style. Shared by the
/// Rules page (the role tile turns over to it) and the Threat Hunter reveal.
library;

import 'package:flutter/material.dart';
import '../i18n.dart';

import '../game/models.dart';
import '../theme/app_theme.dart';
import 'widgets.dart';

/// Official character art, by role. Roles without art leave the space blank.
const Map<RoleId, String> roleArt = {
  RoleId.incidentResponder: 'assets/characters/incident_responder.png',
};

/// Finished card illustrations (frame, art and text in one picture). A role
/// listed here shows this picture as its whole character side, on the Rules
/// page and in the Threat Hunter reveal.
const Map<RoleId, String> roleCardArt = {
  RoleId.red: 'assets/characters/red_team_card.png',
  RoleId.defender: 'assets/characters/defender_card.png',
  RoleId.networkEngineer: 'assets/characters/network_engineer_card.png',
  RoleId.socAnalyst: 'assets/characters/soc_analyst_card.png',
  RoleId.threatHunter: 'assets/characters/threat_hunter_card.png',
};

const _radius = BorderRadius.all(Radius.circular(18));

/// Background of the picture cards, so letterboxing blends with the picture.
const _pictureBg = Color(0xFF303435);

/// Surface, border and glow shared by both sides of the card.
BoxDecoration _cardDecoration(Color accent, {bool glow = false}) => BoxDecoration(
      borderRadius: _radius,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.surfaceHigh, AppColors.surface],
      ),
      border: Border.all(color: accent.withValues(alpha: .45)),
      boxShadow: [
        if (glow) BoxShadow(color: accent.withValues(alpha: .28), blurRadius: 40, spreadRadius: 2),
      ],
    );

/// Character side: nickname on top, art in the middle, the role name as the
/// headline at the bottom.
class RoleCardFace extends StatelessWidget {
  const RoleCardFace({
    super.key,
    required this.info,
    this.trailing,
    this.footer,
    this.glow = false,
  });

  final RoleInfo info;

  /// Widget at the end of the top row (the Rules page's flip-back button).
  final Widget? trailing;

  /// Small line under the tagline (the player who holds the card).
  final String? footer;

  /// Outer glow in the team colour, for the full-screen reveal.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.team(info.team);
    final card = roleCardArt[info.id];
    if (card != null) return _pictureCard(card, color);
    final art = roleArt[info.id];
    return DecoratedBox(
      decoration: _cardDecoration(color, glow: glow),
      child: ClipRRect(
        borderRadius: _radius,
        child: Stack(
          children: [
            // Soft team-coloured halo behind the character.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -.15),
                    radius: .75,
                    colors: [color.withValues(alpha: .16), color.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            if (art != null)
              Positioned.fill(
                top: 56,
                bottom: 110,
                child: Image.asset(
                  art,
                  fit: BoxFit.contain,
                  semanticLabel: tr('The ${info.name} character', 'Le personnage ${info.name}'),
                ),
              ),
            // Fade the feet into the surface so the name sits on a clean base.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 170,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.surface.withValues(alpha: 0), AppColors.surface],
                    stops: const [0, .6],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: trailing == null ? 16 : 8,
              top: trailing == null ? 16 : 8,
              child: Row(
                children: [
                  TeamPerson(info.team),
                  const SizedBox(width: 10),
                  TeamBadge(info.team.label, color),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Role name as the headline; wraps on two lines if needed.
                  Text(info.name.toUpperCase(), style: AppText.ui(42, color: AppColors.text, height: .9)),
                  const SizedBox(height: 10),
                  Text(info.tagline,
                      style: AppText.body(13, color: AppColors.muted, height: 1.35)),
                  if (footer != null) ...[
                    const SizedBox(height: 6),
                    Text(footer!, style: AppText.body(12, color: AppColors.textSoft)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The whole side is the finished illustration. The flip button and the
  /// player's name sit on top of it.
  Widget _pictureCard(String asset, Color color) => DecoratedBox(
        decoration: BoxDecoration(
          color: _pictureBg,
          borderRadius: _radius,
          border: Border.all(color: color.withValues(alpha: .45)),
          boxShadow: [
            if (glow) BoxShadow(color: color.withValues(alpha: .28), blurRadius: 40, spreadRadius: 2),
          ],
        ),
        child: ClipRRect(
          borderRadius: _radius,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  asset,
                  fit: BoxFit.contain,
                  semanticLabel: '${info.name} card. ${info.tagline}',
                ),
              ),
              if (trailing != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.bg.withValues(alpha: .7),
                      shape: BoxShape.circle,
                    ),
                    child: trailing!,
                  ),
                ),
              if (footer != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.bg.withValues(alpha: .8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(footer!, style: AppText.body(12, color: AppColors.textSoft)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

/// Face-down side, shown before the card turns over.
class RoleCardBack extends StatelessWidget {
  const RoleCardBack({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: _cardDecoration(AppColors.primary),
        child: ClipRRect(
          borderRadius: _radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -.1),
                radius: .8,
                colors: [
                  AppColors.primary.withValues(alpha: .12),
                  AppColors.primary.withValues(alpha: 0),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Insider\nThreat'.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppText.ui(52, color: AppColors.text, height: .9)),
                  const SizedBox(height: 14),
                  TeamBadge(tr('Role card', 'Carte de rôle'), AppColors.primary),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Small coloured label, e.g. "BLUE TEAM".
class TeamBadge extends StatelessWidget {
  const TeamBadge(this.text, this.color, {super.key});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text.toUpperCase(),
            style: AppText.body(11, weight: FontWeight.w700, color: color, spacing: .6)),
      );
}
