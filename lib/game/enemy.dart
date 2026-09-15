import 'package:vector_math/vector_math_64.dart';
import '../utils/constants.dart';

class Enemy {
  Vector3 position;
  Vector3 startPos;
  double patrolMinX;
  double patrolMaxX;
  double speed;
  int dir = 1;
  bool isAlive = true;
  double deathTimer = 0;
  double squash = 0;

  Enemy({
    required this.position,
    required this.patrolMinX,
    required this.patrolMaxX,
    this.speed = 1.5,
  }) : startPos = position.clone();

  void update(double dt) {
    if (!isAlive) {
      deathTimer += dt;
      squash = (deathTimer * 8).clamp(0, 1);
      return;
    }

    position.x += dir * speed * dt;

    if (position.x <= patrolMinX) {
      position.x = patrolMinX;
      dir = 1;
    } else if (position.x >= patrolMaxX) {
      position.x = patrolMaxX;
      dir = -1;
    }
  }

  void die() {
    isAlive = false;
    deathTimer = 0;
  }

  bool get shouldRemove => !isAlive && deathTimer > 0.6;
}