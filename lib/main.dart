import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'game/jump_hero_game.dart';
import 'widgets/game_overlay.dart';
import 'widgets/main_menu.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight, DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const JumpHeroApp());
}

class JumpHeroApp extends StatefulWidget {
  const JumpHeroApp({super.key});
  @override
  State<JumpHeroApp> createState() => _JumpHeroAppState();
}

class _JumpHeroAppState extends State<JumpHeroApp> with WidgetsBindingObserver {
  late JumpHeroGame _game;
  bool _showMenu = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = JumpHeroGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _game.pauseEngine();
    } else if (state == AppLifecycleState.resumed) {
      _game.resumeEngine();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jump Hero 3D',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: Scaffold(
        body: _showMenu
            ? MainMenu(onPlay: () => setState(() => _showMenu = false))
            : GameWidget(
                game: _game,
                overlayBuilderMap: {
                  'hud': (context, game) => GameOverlay(game: game as JumpHeroGame),
                },
                initialActiveOverlays: const ['hud'],
                backgroundBuilder: (context) => Container(color: const Color(0xFF87CEEB)),
              ),
      ),
    );
  }
}