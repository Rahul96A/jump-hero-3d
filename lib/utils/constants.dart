import 'package:vector_math/vector_math_64.dart';

class GameConstants {
  // Physics
  static const double gravity = -18.0;
  static const double jumpForce = 8.5;
  static const double walkSpeed = 3.5;
  static const double runSpeed = 6.0;
  static const double groundPoundForce = -14.0;
  static const bool doubleJumpEnabled = true;
  static const double fallThreshold = -15.0;
  
  // Timings - Mario feel
  static const double coyoteTime = 0.15;
  static const double jumpBufferTime = 0.15;
  static const double groundPoundCooldown = 0.5;

  // Player
  static const double playerHeight = 1.8;
  static const double playerRadius = 0.4;
  static final Vector3 playerStart = Vector3(0, 2, 0);
  static final Vector3 checkpointStart = Vector3(0, 2, 0);

  // Camera
  static final Vector3 cameraOffset = Vector3(0, 3.5, -6.5);
  static const double cameraLerpSpeed = 5.0;
  static const double focalLength = 4.0;
  static const double pixelsPerUnit = 65.0;

  // World
  static const int coinsPerLevel = 10;
  static const double coinCollectDistance = 1.2;
  static const double enemyPatrolSpeed = 1.5;

  // Use real 3D model if you drop hero.glb
  static const bool use3DModel = false;
}