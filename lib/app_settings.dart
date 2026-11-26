/// App-wide settings: sound and how much help the Narrator gets. Saved on the
/// phone so they survive a restart.
library;

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'i18n.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final instance = AppSettings._();

  static const _kSound = 'sound_on';
  static const _kVolume = 'volume';
  static const _kTips = 'narrator_tips';
  static const _kLang = 'language';

  SharedPreferences? _prefs;

  /// Master switch for every sound of the app.
  bool soundOn = true;

  /// Master volume, 0..1, applied on top of each sound's own level.
  double volume = 1;

  /// Shows the extra "what to do" line under each step, for new Narrators.
  bool narratorTips = true;

  /// Language of the whole app. Defaults to the phone's language (French if
  /// the phone is in French, English otherwise).
  AppLanguage language =
      PlatformDispatcher.instance.locale.languageCode == 'fr' ? AppLanguage.fr : AppLanguage.en;

  /// What every sound is multiplied by.
  double get gain => soundOn ? volume : 0;

  Future<void> load() async {
    try {
      final p = _prefs = await SharedPreferences.getInstance();
      soundOn = p.getBool(_kSound) ?? soundOn;
      volume = (p.getDouble(_kVolume) ?? volume).clamp(0.0, 1.0);
      narratorTips = p.getBool(_kTips) ?? narratorTips;
      final lang = p.getString(_kLang);
      if (lang != null) language = lang == 'fr' ? AppLanguage.fr : AppLanguage.en;
      notifyListeners();
    } catch (_) {
      // No storage (tests, odd platform): keep the defaults.
    }
  }

  void setSoundOn(bool v) {
    soundOn = v;
    _prefs?.setBool(_kSound, v);
    notifyListeners();
  }

  void setVolume(double v) {
    volume = v.clamp(0.0, 1.0);
    // Moving the slider up turns the sound back on.
    if (volume > 0 && !soundOn) {
      soundOn = true;
      _prefs?.setBool(_kSound, true);
    }
    _prefs?.setDouble(_kVolume, volume);
    notifyListeners();
  }

  void setLanguage(AppLanguage v) {
    if (v == language) return;
    language = v;
    _prefs?.setString(_kLang, v.name);
    notifyListeners();
  }

  void setNarratorTips(bool v) {
    narratorTips = v;
    _prefs?.setBool(_kTips, v);
    notifyListeners();
  }
}
