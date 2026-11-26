/// English / French. Every text the players or the Narrator see goes through
/// [tr], which picks the language set in the settings. Texts are built when
/// they are shown, so switching language applies at once, even mid-game.
library;

import 'package:flutter/widgets.dart';

import 'app_settings.dart';

enum AppLanguage { en, fr }

bool get isFr => AppSettings.instance.language == AppLanguage.fr;

/// The English or the French text, depending on the current language.
String tr(String en, String fr) => isFr ? fr : en;

/// Rebuilds the whole app below it when the language changes, keeping every
/// screen, dialog and game state where it is.
class LanguageScope extends StatefulWidget {
  const LanguageScope({super.key, required this.child});

  final Widget child;

  @override
  State<LanguageScope> createState() => _LanguageScopeState();
}

class _LanguageScopeState extends State<LanguageScope> {
  AppLanguage _lang = AppSettings.instance.language;

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_onSettings);
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() {
    final lang = AppSettings.instance.language;
    if (lang == _lang) return;
    _lang = lang;
    // const widgets are skipped by a normal rebuild: mark every element dirty.
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }
    if (mounted) (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
