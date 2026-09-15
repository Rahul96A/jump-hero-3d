import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'dart:math' as math;

import 'game_world.dart';
import '../utils/constants.dart';
import 'platform.dart';

class JumpHeroGame extends FlameGame with KeyboardEvents, HasCollisionDetection, PanDetector, ScrollDetector {
  final GameWorld world = GameWorld();
  bool _isRunning = false;
  vm.Vector2 _moveInput = vm.Vector2.zero();

  bool get isRunning => _isRunning;
  GameWorld get gameWorld => world;

  @override
  Future<void> onLoad() async {
    await world.loadLevel();
  }

  @override
  void update(double dt) {
    super.update(dt);
    world.update(dt);
    world.setMoveInput(_moveInput, _isRunning);
  }

  // --- 3D Projection Helpers ---
  vm.Vector2? project3D(vm.Vector3 worldPos, Size screenSize) {
    final camPos = world.camera.position;
    final focal = GameConstants.focalLength;

    final rel = worldPos - camPos;
    
    // Simple perspective with camera looking towards -Z initially? We use yaw rotation
    // Apply inverse yaw rotation to get camera space
    final yaw = world.camera.yaw;
    final cosYaw = math.cos(-yaw);
    final sinYaw = math.sin(-yaw);
    
    // Rotate around Y axis
    final x = rel.x * cosYaw - rel.z * sinYaw;
    final z = rel.x * sinYaw + rel.z * cosYaw;
    final y = rel.y;

    // If behind camera, don't render (z > 0 means behind because camera looks towards -Z after rotation)
    // In our setup, camera is behind player looking forward, so we want points in front of camera (z < 0 in camera space after transform? Let's simplify)
    // For stability: use distance along forward vector
    final forward = vm.Vector3(math.sin(yaw), 0, math.cos(yaw));
    final toPoint = worldPos - camPos;
    final depth = toPoint.dot(forward); // positive = in front

    if (depth < 0.3) return null;

    final scale = focal / (focal + depth);
    final center = Offset(screenSize.width / 2, screenSize.height / 2);

    final sx = center.dx + x * scale * GameConstants.pixelsPerUnit;
    final sy = center.dy - y * scale * GameConstants.pixelsPerUnit; // Y up

    return vm.Vector2(sx, sy);
  }

  double depthForSorting(vm.Vector3 pos) {
    final camPos = world.camera.position;
    final yaw = world.camera.yaw;
    final forward = vm.Vector3(math.sin(yaw), 0, math.cos(yaw));
    return (pos - camPos).dot(forward);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (world.level == null) {
      // Loading screen
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), Paint()..color = const Color(0xFF87CEEB));
      final tp = TextPainter(text: const TextSpan(text: 'Loading Jump Hero 3D...', style: TextStyle(color: Colors.white, fontSize: 24)), textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(size.x/2 - tp.width/2, size.y/2));
      return;
    }

    final screenSize = Size(size.x, size.y);

    // Sky gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5DC1FF), Color(0xFF87CEEB), Color(0xFFE0F6FF)],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), skyPaint);

    // Collect all renderables for depth sorting (far to near)
    final List<_RenderItem> items = [];

    for (final p in world.level!.platforms) {
      items.add(_RenderItem(pos: p.position, type: _RenderType.platform, ref: p, depth: depthForSorting(p.position)));
    }
    for (final pipe in world.level!.pipes) {
      items.add(_RenderItem(pos: pipe.position, type: _RenderType.pipe, ref: pipe, depth: depthForSorting(pipe.position)));
    }
    for (final coin in world.level!.coins) {
      if (!coin.collected) items.add(_RenderItem(pos: coin.position, type: _RenderType.coin, ref: coin, depth: depthForSorting(coin.position)));
    }
    for (final enemy in world.level!.enemies) {
      items.add(_RenderItem(pos: enemy.position, type: _RenderType.enemy, ref: enemy, depth: depthForSorting(enemy.position)));
    }
    items.add(_RenderItem(pos: world.level!.finishFlag.position, type: _RenderType.finish, depth: depthForSorting(world.level!.finishFlag.position)));
    items.add(_RenderItem(pos: world.player.position, type: _RenderType.player, depth: depthForSorting(world.player.position)));

    // Sort far -> near
    items.sort((a,b) => b.depth.compareTo(a.depth));

    for (final item in items) {
      _renderItem(canvas, item, screenSize);
    }

    // Ground shadow for player (always visible)
    _drawShadow(canvas, world.player.position, screenSize);
  }

  void _drawShadow(Canvas canvas, vm.Vector3 pos, Size screenSize) {
    final groundY = 0.0;
    final shadowPos = vm.Vector3(pos.x, groundY + 0.05, pos.z);
    final proj = project3D(shadowPos, screenSize);
    if (proj == null) return;
    final depth = depthForSorting(shadowPos);
    if (depth < 0) return;
    final scale = GameConstants.focalLength / (GameConstants.focalLength + depth);
    final size = 18 * scale;
    final paint = Paint()..color = Colors.black.withOpacity(0.25 * scale.clamp(0,1));
    canvas.drawOval(Rect.fromCenter(center: Offset(proj.x, proj.y), width: size*2, height: size), paint);
  }

  void _renderItem(Canvas canvas, _RenderItem item, Size screenSize) {
    final proj = project3D(item.pos, screenSize);
    if (proj == null) return;
    final depth = item.depth;
    if (depth < 0.1) return;

    final scale = (GameConstants.focalLength / (GameConstants.focalLength + depth)).clamp(0.1, 2.5);
    final focalScale = scale * GameConstants.pixelsPerUnit;

    switch (item.type) {
      case _RenderType.platform:
        final plat = item.ref as Platform;
        _drawPlatform(canvas, proj, plat, scale, focalScale);
        break;
      case _RenderType.pipe:
        _drawPipe(canvas, proj, scale, focalScale);
        break;
      case _RenderType.coin:
        final coin = item.ref as dynamic;
        _drawCoin(canvas, proj, coin, scale);
        break;
      case _RenderType.enemy:
        final enemy = item.ref as dynamic;
        _drawEnemy(canvas, proj, enemy, scale, focalScale);
        break;
      case _RenderType.player:
        _drawPlayer(canvas, proj, scale, focalScale);
        break;
      case _RenderType.finish:
        _drawFinish(canvas, proj, scale, focalScale);
        break;
    }
  }

  void _drawPlatform(Canvas canvas, vm.Vector2 proj, Platform plat, double scale, double focalScale) {
    final w = plat.size.x * focalScale;
    final h = plat.size.y * focalScale * 0.5;
    final d = plat.size.z * focalScale * 0.3;

    // Top face
    final topRect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(proj.x, proj.y), width: w, height: h), const Radius.circular(4));
    final isMoving = plat.isMoving;
    final baseColor = isMoving ? const Color(0xFF8D6E63) : const Color(0xFF43A047);
    final topColor = isMoving ? const Color(0xFFA1887F) : const Color(0xFF66BB6A);
    
    canvas.drawRRect(topRect, Paint()..color = baseColor);
    // top highlight
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(proj.x, proj.y - h*0.15), width: w*0.9, height: h*0.5), const Radius.circular(3)), Paint()..color = topColor);

    // Side depth - simple 3D extrusion
    if (d > 2) {
      final sidePath = Path()
        ..moveTo(proj.x - w/2, proj.y)
        ..lineTo(proj.x - w/2 + d*0.2, proj.y + d*0.3)
        ..lineTo(proj.x + w/2 + d*0.2, proj.y + d*0.3)
        ..lineTo(proj.x + w/2, proj.y)
        ..close();
      canvas.drawPath(sidePath, Paint()..color = Colors.black.withOpacity(0.2));
    }

    if (isMoving) {
      // arrows
      final arrowPaint = Paint()..color = Colors.white.withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 2*scale;
      canvas.drawLine(Offset(proj.x - w*0.3, proj.y), Offset(proj.x + w*0.3, proj.y), arrowPaint);
    }
  }

  void _drawPipe(Canvas canvas, vm.Vector2 proj, double scale, double focalScale) {
    final w = 20 * scale * 3;
    final h = 40 * scale * 3;
    final rect = Rect.fromCenter(center: Offset(proj.x, proj.y - h*0.3), width: w, height: h);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(w*0.3));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF2E7D32));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(proj.x, proj.y - h*0.6), width: w*1.3, height: h*0.3), Radius.circular(w*0.2)), Paint()..color = const Color(0xFF388E3C));
  }

  void _drawCoin(Canvas canvas, vm.Vector2 proj, dynamic coin, double scale) {
    final rot = coin.rotationY as double;
    final w = 14 * scale * 3 * (0.5 + 0.5 * (math.sin(rot).abs()));
    final h = 20 * scale * 3;
    final rect = Rect.fromCenter(center: Offset(proj.x, proj.y), width: w, height: h);
    final paint = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawOval(rect, paint);
    canvas.drawOval(rect, Paint()..color = Colors.white.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  void _drawEnemy(Canvas canvas, vm.Vector2 proj, dynamic enemy, double scale, double focalScale) {
    final isAlive = enemy.isAlive as bool;
    final squash = enemy.squash as double;
    final w = 18 * scale * 3;
    final h = (18 * scale * 3) * (isAlive ? 1 : (1 - squash*0.7));
    
    if (!isAlive && squash > 0.9) return;

    // Body
    final bodyRect = Rect.fromCenter(center: Offset(proj.x, proj.y - h*0.2), width: w, height: h);
    canvas.drawOval(bodyRect, Paint()..color = const Color(0xFF8D6E63));
    // Head
    final headRect = Rect.fromCenter(center: Offset(proj.x, proj.y - h*0.7), width: w*1.1, height: h*0.6);
    canvas.drawOval(headRect, Paint()..color = const Color(0xFFD32F2F));
    // Eyes
    canvas.drawCircle(Offset(proj.x - w*0.2, proj.y - h*0.7), 3*scale, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(proj.x + w*0.2, proj.y - h*0.7), 3*scale, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(proj.x - w*0.2, proj.y - h*0.65), 1.5*scale, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(proj.x + w*0.2, proj.y - h*0.65), 1.5*scale, Paint()..color = Colors.black);

    // Direction arrow
    final dir = enemy.dir as int;
    canvas.drawLine(Offset(proj.x, proj.y), Offset(proj.x + dir * w*0.3, proj.y), Paint()..color = Colors.black26..strokeWidth = 2);
  }

  void _drawPlayer(Canvas canvas, vm.Vector2 proj, double scale, double focalScale) {
    final player = world.player;
    final h = GameConstants.playerHeight * focalScale * 0.9;
    final w = 14 * scale * 3;

    // Body - blue overalls
    final bodyTop = proj.y - h*0.3;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(proj.x, bodyTop), width: w, height: h*0.5), const Radius.circular(6)), Paint()..color = const Color(0xFF1565C0));
    // Shirt - red
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(proj.x, bodyTop - h*0.15), width: w*1.1, height: h*0.25), const Radius.circular(4)), Paint()..color = const Color(0xFFE53935));
    // Head - skin
    canvas.drawCircle(Offset(proj.x, bodyTop - h*0.45), w*0.35, Paint()..color = const Color(0xFFFFCC80));
    // Cap - red
    canvas.drawOval(Rect.fromCenter(center: Offset(proj.x, bodyTop - h*0.55), width: w*0.9, height: w*0.5), Paint()..color = const Color(0xFFD32F2F));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(proj.x + w*0.15, bodyTop - h*0.5), width: w*0.7, height: w*0.2), const Radius.circular(2)), Paint()..color = const Color(0xFFD32F2F));

    // State indicator
    if (player.state.toString().contains('jumping') || player.state.toString().contains('falling')) {
      // jump dust
      canvas.drawCircle(Offset(proj.x, proj.y + h*0.1), 4*scale, Paint()..color = Colors.white.withOpacity(0.3));
    }

    if (player.isGroundPounding) {
      canvas.drawCircle(Offset(proj.x, proj.y), w*1.2, Paint()..color = Colors.orange.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 3);
    }
  }

  void _drawFinish(Canvas canvas, vm.Vector2 proj, double scale, double focalScale) {
    final h = 50 * scale * 3;
    final w = 6 * scale;
    // Pole
    canvas.drawRect(Rect.fromCenter(center: Offset(proj.x, proj.y - h*0.4), width: w, height: h), Paint()..color = Colors.white);
    // Flag - checkered
    final flagRect = Rect.fromLTWH(proj.x + w*0.5, proj.y - h*0.8, 24*scale*3, 16*scale*3);
    final flagPaint = Paint()..color = const Color(0xFF43A047);
    canvas.drawRect(flagRect, flagPaint);
    // checker pattern
    for (int i=0;i<2;i++) {
      for (int j=0;j<2;j++) {
        if ((i+j)%2==0) {
          canvas.drawRect(Rect.fromLTWH(flagRect.left + i*flagRect.width/2, flagRect.top + j*flagRect.height/2, flagRect.width/2, flagRect.height/2), Paint()..color = Colors.white);
        }
      }
    }
    if (world.level!.finishFlag.reached) {
      canvas.drawCircle(Offset(proj.x, proj.y - h*0.8), 30*scale, Paint()..color = Colors.yellow.withOpacity(0.4));
    }
  }

  // Input handling
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _moveInput = vm.Vector2.zero();
    _isRunning = keysPressed.contains(LogicalKeyboardKey.shiftLeft) || keysPressed.contains(LogicalKeyboardKey.shiftRight);

    if (keysPressed.contains(LogicalKeyboardKey.keyW) || keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      _moveInput.y += 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) || keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      _moveInput.y -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      _moveInput.x -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) || keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      _moveInput.x += 1;
    }

    if (_moveInput.length > 1) _moveInput.normalize();

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        world.jump();
      }
      if (event.logicalKey == LogicalKeyboardKey.keyQ) {
        world.groundPound();
      }
    }

    return KeyEventResult.handled;
  }

  // Touch camera orbit
  vm.Vector2? _lastPan;

  @override
  void onPanStart(DragStartInfo info) {
    _lastPan = vm.Vector2(info.raw.globalPosition.dx, info.raw.globalPosition.dy);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    final current = vm.Vector2(info.raw.globalPosition.dx, info.raw.globalPosition.dy);
    if (_lastPan != null) {
      final delta = current - _lastPan!;
      // Only orbit if dragging on right half
      if (current.x > size.x * 0.5) {
        world.orbitCamera(delta.x, -delta.y);
      }
    }
    _lastPan = current;
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _lastPan = null;
  }

  @override
  void onScroll(PointerScrollInfo info) {
    world.zoomCamera(info.scrollDelta.global.y * 0.01);
  }

  // External API for overlay joystick
  void setJoystickInput(vm.Vector2 input) {
    _moveInput = input;
  }

  void setRunning(bool running) {
    _isRunning = running;
  }

  void jumpPressed() => world.jump();
  void groundPoundPressed() => world.groundPound();
}

enum _RenderType { platform, pipe, coin, enemy, player, finish }

class _RenderItem {
  vm.Vector3 pos;
  _RenderType type;
  dynamic ref;
  double depth;
  _RenderItem({required this.pos, required this.type, this.ref, required this.depth});
}