import 'package:vector_math/vector_math_64.dart';
import 'player.dart';
import 'platform.dart';
import 'enemy.dart';
import 'coin.dart';
import 'camera_controller.dart';
import '../levels/level_data.dart';
import '../utils/constants.dart';

enum GameStatus { loading, playing, paused, gameOver, levelComplete }

class GameWorld {
  Player player;
  CameraController camera;
  LevelData? level;
  GameStatus status = GameStatus.loading;
  double elapsed = 0;

  GameWorld()
      : player = Player(),
        camera = CameraController(initialTarget: GameConstants.playerStart);

  Future<void> loadLevel() async {
    status = GameStatus.loading;
    level = await LevelData.loadFromJson('lib/levels/level_1.json');
    // If asset loading fails (web), fallback already handled inside loadFromJson
    player = Player(startPos: GameConstants.playerStart.clone());
    camera = CameraController(initialTarget: player.position.clone());
    status = GameStatus.playing;
  }

  void update(double dt) {
    if (status != GameStatus.playing) return;
    elapsed += dt;

    // Update platforms
    for (final p in level!.platforms) {
      p.update(dt);
    }
    for (final e in level!.enemies) {
      e.update(dt);
    }
    for (final c in level!.coins) {
      c.update(dt);
    }

    player.update(dt, level!.platforms);

    // Coin collection
    for (final c in level!.coins) {
      if (!c.collected) {
        final dist = (c.position - player.position).length;
        if (dist < GameConstants.coinCollectDistance) {
          c.collected = true;
          player.collectCoin();
        }
      }
    }

    // Enemy collision
    for (final e in level!.enemies) {
      if (!e.isAlive || e.shouldRemove) continue;
      final dist = (e.position - player.position).length;
      if (dist < 1.0) {
        final isTopHit = player.velocity.y < 0 && player.position.y > e.position.y + 0.6;
        if (isTopHit || player.isGroundPounding) {
          e.die();
          player.bounce();
          player.score += 200;
        } else {
          player.takeDamage();
          if (player.lives <= 0) {
            status = GameStatus.gameOver;
          }
        }
      }
    }

    // Remove dead enemies
    level!.enemies.removeWhere((e) => e.shouldRemove);

    // Finish flag
    final finishDist = (level!.finishFlag.position - player.position).length;
    if (finishDist < 1.5) {
      level!.finishFlag.reached = true;
      status = GameStatus.levelComplete;
      player.score += 1000;
    }

    // Camera
    camera.follow(player.position, dt);

    // Game over check
    if (player.lives <= 0) {
      status = GameStatus.gameOver;
    }
  }

  void reset() {
    player = Player(startPos: GameConstants.playerStart.clone());
    camera = CameraController(initialTarget: player.position.clone());
    level!.finishFlag.reached = false;
    for (final c in level!.coins) {
      c.collected = false;
    }
    status = GameStatus.playing;
    elapsed = 0;
    // Reload level positions for moving platforms etc.
    loadLevel();
  }

  // Input proxies
  void setMoveInput(Vector2 input, bool running) {
    player.setInput(input, running);
  }

  void jump() => player.jump();
  void groundPound() => player.groundPound();
  void orbitCamera(double dx, double dy) => camera.addOrbit(dx, dy);
  void zoomCamera(double delta) => camera.addZoom(delta);

  bool get allCoinsCollected => level != null && level!.coins.every((c) => c.collected);
}