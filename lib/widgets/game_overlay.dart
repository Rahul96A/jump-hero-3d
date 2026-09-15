import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../game/jump_hero_game.dart';
import '../game/game_world.dart';

class GameOverlay extends StatefulWidget {
  final JumpHeroGame game;
  const GameOverlay({super.key, required this.game});

  @override
  State<GameOverlay> createState() => _GameOverlayState();
}

class _GameOverlayState extends State<GameOverlay> {
  bool isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // HUD Top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _hudCard(
                    children: [
                      _hudItem(Icons.monetization_on, Colors.amber, '${widget.game.world.player.coins} / 10'),
                      const SizedBox(width: 12),
                      _hudItem(Icons.favorite, Colors.red, 'x${widget.game.world.player.lives}'),
                      const SizedBox(width: 12),
                      _hudItem(Icons.star, Colors.yellow, '${widget.game.world.player.score}'),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (widget.game.world.status == GameStatus.paused) {
                              widget.game.world.status = GameStatus.playing;
                            } else {
                              widget.game.world.status = GameStatus.paused;
                            }
                          });
                        },
                        icon: Icon(widget.game.world.status == GameStatus.paused ? Icons.play_arrow : Icons.pause, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => widget.game.world.reset(),
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Controls hint for desktop
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20)),
              child: const Text('WASD Move • SHIFT Run • SPACE Jump • Q Ground Pound • Right-drag Orbit • Scroll Zoom', style: TextStyle(color: Colors.white70, fontSize: 10)),
            ),
          ),
        ),

        // Mobile Joystick + Buttons
        Positioned(
          bottom: 20,
          left: 20,
          child: Joystick(
            mode: JoystickMode.all,
            listener: (details) {
              final vec = vm.Vector2(details.x, details.y);
              // invert Y because screen Y down vs world Z
              widget.game.setJoystickInput(vm.Vector2(vec.x, vec.y));
            },
            base: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2)),
            ),
            stick: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
            ),
          ),
        ),

        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            children: [
              // Run toggle
              GestureDetector(
                onTapDown: (_) {
                  setState(() => isRunning = true);
                  widget.game.setRunning(true);
                },
                onTapUp: (_) {
                  setState(() => isRunning = false);
                  widget.game.setRunning(false);
                },
                onTapCancel: () {
                  setState(() => isRunning = false);
                  widget.game.setRunning(false);
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: isRunning ? Colors.orange : Colors.black45, shape: BoxShape.circle, border: Border.all(color: Colors.white54)),
                  child: const Center(child: Text('B', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTapDown: (_) => widget.game.jumpPressed(),
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]),
                  child: const Center(child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28))),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTapDown: (_) => widget.game.groundPoundPressed(),
                child: Container(
                  width: 56,
                  height: 36,
                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white54)),
                  child: const Center(child: Icon(Icons.arrow_downward, color: Colors.white, size: 18)),
                ),
              ),
            ],
          ),
        ),

        // Game State Overlays
        if (widget.game.world.status == GameStatus.paused) _pauseMenu(),
        if (widget.game.world.status == GameStatus.gameOver) _gameOverMenu(),
        if (widget.game.world.status == GameStatus.levelComplete) _levelCompleteMenu(),
      ],
    );
  }

  Widget _hudCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
      child: Row(children: children),
    );
  }

  Widget _hudItem(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _pauseMenu() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('PAUSED', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => setState(() => widget.game.world.status = GameStatus.playing), child: const Text('Resume')),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () => widget.game.world.reset(), child: const Text('Restart Level')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gameOverMenu() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('GAME OVER', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 12),
                Text('Score: ${widget.game.world.player.score}', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: () => widget.game.world.reset(), child: const Text('Try Again')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _levelCompleteMenu() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('LEVEL COMPLETE!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 12),
                Text('Coins: ${widget.game.world.player.coins}/10', style: const TextStyle(fontSize: 16)),
                Text('Score: ${widget.game.world.player.score}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(widget.game.world.allCoinsCollected ? 'Perfect! All coins!' : 'Good run!', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: () => widget.game.world.reset(), child: const Text('Play Again')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}