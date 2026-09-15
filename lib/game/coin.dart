import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

class Coin {
  Vector3 position;
  bool collected = false;
  double rotationY = 0;
  double bobTime = 0;
  double baseY;

  Coin({required this.position}) : baseY = position.y;

  void update(double dt) {
    if (collected) return;
    rotationY += dt * 2.5;
    bobTime += dt * 2.0;
    position.y = baseY + math.sin(bobTime) * 0.15;
  }
}