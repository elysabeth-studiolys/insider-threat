/// Semantic design tokens, mapped onto the raw ramps in `palette.dart`
/// (lime / pink / blue / grey, primary = the -400 step). Re-skinning the app
/// starts here.
///
/// Roles: [primary] (lime) is the brand accent and the call to action, kept
/// for what is actionable or selected so it does not dominate. [secondary]
/// (pink) is the second accent. [danger] (red) is for warnings and errors. Team
/// colours ([teamRed], [teamBlue]) identify the sides only.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/models.dart';
import 'palette.dart';

abstract final class AppColors {
  // Neutrals: dark background, surfaces get lighter as they rise.
  static const bg = Cod.c950;
  static const surface = Cod.c900;
  static const surfaceHigh = Cod.c800;
  static const line = Cod.c800;
  static const text = Cod.c50;
  static const textSoft = Cod.c300;
  static const muted = Cod.c400;
  static const disabledBg = Cod.c900;
  static const disabledText = Cod.c600;

  // Brand / actionable / selected.
  static const primary = Lime.c400;
  static const primarySoft = Lime.c200;
  static const onAccent = Cod.c950;

  // Secondary: second accent after the brand lime (badges, narration card,
  // labels, scanner chrome).
  static const secondary = Blush.c400;
  static const secondarySoft = Blush.c200;

  // Danger: warnings, destructive actions, errors. Red, so it stays distinct
  // from the pink secondary.
  static const danger = Signal.c400;
  static const dangerSoft = Signal.c200;

  // Team colours: data, not UI chrome. Keep them for team identity only.
  static const teamRed = Signal.c400;
  static const teamBlue = Picton.c400;
  static const teamPurple = Violet.c400;

  /// Faint grid lines on the Event card.
  static const grid = Color(0x17A5A5A1);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Lime.c400, Lime.c500],
  );
  static const dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Signal.c400, Signal.c500],
  );
  static const teamBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Picton.c300, Picton.c400],
  );

  static Color team(Team t) => switch (t) {
        Team.red => teamRed,
        Team.blue => teamBlue,
        Team.purple => teamPurple,
      };
}

abstract final class AppText {
  /// Tests turn this off so that no font is fetched from the network.
  static bool useGoogleFonts = true;

  /// Titles: Schabo Condensed, bundled. It has a single weight, so [weight]
  /// is ignored (no faux bold), and it runs small for its size, hence [_titleScale].
  static const _titleScale = 1.5;

  static TextStyle ui(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.text,
    double? height,
    double? spacing,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontFamily: 'Schabo',
        fontSize: size * _titleScale,
        fontWeight: FontWeight.w400,
        color: color,
        height: height,
        letterSpacing: spacing,
        decoration: decoration,
      );

  /// Body copy, labels and buttons: Satoshi, bundled (assets/fonts) so it
  /// works offline. Titles use [ui].
  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.text,
    double? height,
    double? spacing,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontFamily: 'Satoshi',
        fontSize: size,
        fontWeight: weight,
        // Satoshi is a variable font: drive its weight axis explicitly.
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
        color: color,
        height: height,
        letterSpacing: spacing,
        decoration: decoration,
      );

  static TextStyle mono(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.muted,
    double? height,
    double? spacing,
  }) {
    final base = TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
    );
    return useGoogleFonts ? GoogleFonts.jetBrainsMono(textStyle: base) : base;
  }
}

ThemeData buildAppTheme() => ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      // No ripple or highlight anywhere: pressed state is a yellow border
      // (see Pressable).
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onAccent,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onAccent,
        tertiary: AppColors.teamBlue,
        onTertiary: AppColors.onAccent,
        error: AppColors.danger,
        onError: AppColors.onAccent,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        outline: AppColors.line,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
