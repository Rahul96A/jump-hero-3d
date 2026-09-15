import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

class Platform {
  Vector3 position;
  Vector3 size;
  bool isMoving;
  Vector3 moveFrom;
  Vector3 moveTo;
  Vector3 delta = Vector3.zero();
  double _time = 0;
  Vector3 _lastPos;

  Platform({
    required this.position,
    required this.size,
    this.isMoving = false,
    Vector3? from,
    Vector3? to,
  })  : moveFrom = from ?? position.clone(),
        moveTo = to ?? position.clone(),
        _lastPos = position.clone();

  void update(double dt) {
    _lastPos = position.clone();
    if (!isMoving) {
      delta = Vector3.zero();
      return;
    }
    _time += dt * 0.6; // speed
    final t = (math.sin(_time) + 1) / 2; // 0..1
    position = moveFrom * (1 - t) + moveTo * t;
    delta = position - _lastPos;
  }
}

class Pipe {
  Vector3 position;
  double radius;
  double height;
  Pipe({required this.position, this.radius = 0.6, this.height = 2.0});
}

class FinishFlag {
  Vector3 position;
  bool reached = false;
  FinishFlag({required this.position});
}