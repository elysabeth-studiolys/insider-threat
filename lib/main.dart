import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'i18n.dart';
import 'game/game_controller.dart';
import 'game/guide_step.dart';
import 'game/setup_controller.dart';
import 'theme/app_theme.dart';
import 'ui/event_draw/sfx.dart';
import 'ui/end_screen.dart';
import 'ui/guide_screen.dart';
import 'ui/home_screen.dart';
import 'ui/setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  runApp(const InsiderThreatApp());
}

class InsiderThreatApp extends StatelessWidget {
  const InsiderThreatApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Insider Threat',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        // Switching language in the settings rebuilds every screen in place.
        builder: (context, child) => LanguageScope(child: child!),
        home: const AppRoot(),
      );
}

enum _Screen { home, setup, game }

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _setup = SetupController();
  _Screen _screen = _Screen.home;
  GameController? _game;

  @override
  void dispose() {
    _game?.removeListener(_syncAmbience);
    _game?.dispose();
    _setup.dispose();
    super.dispose();
  }

  void _start() {
    _game?.removeListener(_syncAmbience);
    _game?.dispose();
    setState(() {
      _game = GameController(
        players: _setup.buildPlayers(),
        expert: _setup.expert,
      )..addListener(_syncAmbience);
      _screen = _Screen.game;
    });
    _syncAmbience();
  }

  /// The night ambience plays from Nightfall until Dawn, the day ambience
  /// from the morning report until Nightfall. Each fades out when it ends.
  void _syncAmbience() {
    final game = _game;
    final night = game != null &&
        game.phase == GamePhase.night &&
        game.currentStep.kind != StepKind.dawn;
    final day = game != null && game.phase == GamePhase.day;
    final sfx = Sfx.instance;
    night ? sfx.loop(SfxId.nightAmbience) : sfx.fadeOut(SfxId.nightAmbience);
    // Quieter: the table talks over it all day.
    day ? sfx.loop(SfxId.dayAmbience, volume: 0.35) : sfx.fadeOut(SfxId.dayAmbience);
  }

  void _toSetup() {
    _game?.removeListener(_syncAmbience);
    _game?.dispose();
    Sfx.instance
      ..fadeOut(SfxId.nightAmbience)
      ..fadeOut(SfxId.dayAmbience);
    _setup.clearRoles(); // names stay, new cards are dealt
    setState(() {
      _game = null;
      _screen = _Screen.setup;
    });
  }

  Future<void> _confirmQuit() async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Quit this game?', 'Quitter la partie ?').toUpperCase(), style: AppText.ui(20, weight: FontWeight.w700)),
        content: Text(tr('The current game will be lost.', 'La partie en cours sera perdue.'), style: AppText.body(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Keep playing', 'Continuer')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Quit', 'Quitter'), style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (quit == true) _toSetup();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _screen == _Screen.home,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_screen == _Screen.game) {
          _confirmQuit();
        } else {
          setState(() => _screen = _Screen.home);
        }
      },
      child: switch (_screen) {
        _Screen.home => HomeScreen(
            onNewGame: () => setState(() => _screen = _Screen.setup),
          ),
        _Screen.setup => SetupScreen(
            setup: _setup,
            onBack: () => setState(() => _screen = _Screen.home),
            onStart: _start,
          ),
        _Screen.game => ListenableBuilder(
            listenable: _game!,
            builder: (context, _) => _game!.phase == GamePhase.end
                ? EndScreen(game: _game!, onNewGame: _toSetup)
                : GuideScreen(game: _game!, onQuit: _confirmQuit),
          ),
      },
    );
  }
}
