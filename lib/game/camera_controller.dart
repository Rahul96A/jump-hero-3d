import 'package:vector_math/vector_math_64.dart';
import '../utils/constants.dart';
import 'dart:math' as math;

class CameraController {
  Vector3 position;
  Vector3 target;
  Vector3 offset;
  double yaw = 3.14159; // behind player
  double pitch = 0.2;
  double distance = 6.5;

  CameraController({Vector3? initialTarget})
      : position = (initialTarget ?? Vector3.zero()) + GameConstants.cameraOffset,
        target = initialTarget ?? Vector3.zero(),
        offset = GameConstants.cameraOffset.clone();

  void follow(Vector3 playerPos, double dt) {
    final lerp = (GameConstants.cameraLerpSpeed * dt).clamp(0.0, 1.0);
    target = target * (1 - lerp) + playerPos * lerp;
    
    final desired = Vector3(
      target.x + math.sin(yaw) * distance,
      target.y + 3.5 + pitch * 2,
      target.z + math.cos(yaw) * distance,
    );
    position = position * (1 - lerp) + desired * lerp;
  }

  void addOrbit(double dx, double dy) {
    yaw += dx * 0.01;
    pitch = (pitch + dy * 0.01).clamp(-0.5, 0.8);
  }

  void addZoom(double delta) {
    distance = (distance + delta).clamp(2.5, 10.0);
  }
}