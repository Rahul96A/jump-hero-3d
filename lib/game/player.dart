import 'package:vector_math/vector_math_64.dart';
import '../utils/constants.dart';
import 'platform.dart';

enum PlayerState { idle, walking, running, jumping, falling, groundPounding }

class Player {
  Vector3 position;
  Vector3 velocity;
  bool isGrounded;
  bool wasGrounded;
  PlayerState state;

  int lives;
  int coins;
  int score;

  Vector3 checkpoint;

  double coyoteTimer = 0;
  double jumpBufferTimer = 0;
  double groundPoundCooldown = 0;
  bool canDoubleJump = true;
  bool isGroundPounding = false;

  // Input
  Vector2 moveInput = Vector2.zero();
  bool isRunning = false;

  Player({
    Vector3? startPos,
  })  : position = startPos ?? GameConstants.playerStart.clone(),
        velocity = Vector3.zero(),
        isGrounded = false,
        wasGrounded = false,
        state = PlayerState.idle,
        lives = 3,
        coins = 0,
        score = 0,
        checkpoint = startPos ?? GameConstants.checkpointStart.clone();

  void setInput(Vector2 input, bool running) {
    moveInput = input;
    isRunning = running;
  }

  void jump() {
    jumpBufferTimer = GameConstants.jumpBufferTime;
  }

  void groundPound() {
    if (!isGrounded && groundPoundCooldown <= 0 && !isGroundPounding) {
      isGroundPounding = true;
      velocity.x = 0;
      velocity.z = 0;
      velocity.y = GameConstants.groundPoundForce;
      groundPoundCooldown = GameConstants.groundPoundCooldown;
    }
  }

  void _tryJump() {
    if (isGrounded || coyoteTimer > 0) {
      // Normal jump
      velocity.y = GameConstants.jumpForce;
      isGrounded = false;
      coyoteTimer = 0;
      canDoubleJump = true;
      state = PlayerState.jumping;
      jumpBufferTimer = 0;
    } else if (GameConstants.doubleJumpEnabled && canDoubleJump) {
      // Double jump
      velocity.y = GameConstants.jumpForce * 0.9;
      canDoubleJump = false;
      state = PlayerState.jumping;
      jumpBufferTimer = 0;
    }
  }

  void update(double dt, List<Platform> platforms) {
    wasGrounded = isGrounded;

    // Timers
    if (coyoteTimer > 0) coyoteTimer -= dt;
    if (jumpBufferTimer > 0) {
      jumpBufferTimer -= dt;
      _tryJump();
    }
    if (groundPoundCooldown > 0) groundPoundCooldown -= dt;

    // Horizontal movement
    final speed = isRunning ? GameConstants.runSpeed : GameConstants.walkSpeed;
    final targetVelX = moveInput.x * speed;
    final targetVelZ = moveInput.y * speed; // joystick y -> world Z

    // Smooth accel
    velocity.x = lerpDouble(velocity.x, targetVelX, 12 * dt);
    velocity.z = lerpDouble(velocity.z, targetVelZ, 12 * dt);

    // Apply gravity if not grounded
    if (!isGrounded) {
      velocity.y += GameConstants.gravity * dt;
    }

    // Clamp fall speed
    velocity.y = velocity.y.clamp(-20.0, 20.0);

    // Integrate
    position += velocity * dt;

    // Collision
    checkCollision(platforms);

    // State machine
    if (isGroundPounding && isGrounded) {
      isGroundPounding = false;
      // Camera shake effect could be triggered here
    }

    if (isGrounded) {
      canDoubleJump = true;
      if (moveInput.length < 0.1) {
        state = PlayerState.idle;
      } else {
        state = isRunning ? PlayerState.running : PlayerState.walking;
      }
    } else {
      if (isGroundPounding) {
        state = PlayerState.groundPounding;
      } else if (velocity.y > 0) {
        state = PlayerState.jumping;
      } else {
        state = PlayerState.falling;
      }
      // Coyote timer starts when we just left ground
      if (wasGrounded && !isGrounded) {
        coyoteTimer = GameConstants.coyoteTime;
      }
    }

    // Fall death
    if (position.y < GameConstants.fallThreshold) {
      takeDamage();
    }
  }

  void checkCollision(List<Platform> platforms) {
    isGrounded = false;
    final halfH = GameConstants.playerHeight / 2;
    final r = GameConstants.playerRadius;

    for (final p in platforms) {
      final pMin = p.position - p.size * 0.5;
      final pMax = p.position + p.size * 0.5;

      // AABB check
      final playerMin = Vector3(position.x - r, position.y - halfH, position.z - r);
      final playerMax = Vector3(position.x + r, position.y + halfH, position.z + r);

      if (playerMax.x < pMin.x || playerMin.x > pMax.x) continue;
      if (playerMax.y < pMin.y || playerMin.y > pMax.y) continue;
      if (playerMax.z < pMin.z || playerMin.z > pMax.z) continue;

      // Collision detected - resolve vertical first if landing on top
      if (velocity.y <= 0 && playerMin.y <= pMax.y && (position.y - halfH) >= pMax.y - 0.3 && wasGrounded || velocity.y < 0) {
        // Top collision
        if (position.y - halfH <= pMax.y && position.y > p.position.y) {
          position.y = pMax.y + halfH + 0.01;
          velocity.y = 0;
          isGrounded = true;
          // Move with platform if moving
          if (p.isMoving) {
            position += p.delta * 1.0;
          }
          continue;
        }
      }

      // Side collisions - push out
      final overlapX = (playerMax.x - pMin.x).abs() < (pMax.x - playerMin.x).abs() ? playerMax.x - pMin.x : pMax.x - playerMin.x;
      final overlapZ = (playerMax.z - pMin.z).abs() < (pMax.z - playerMin.z).abs() ? playerMax.z - pMin.z : pMax.z - playerMin.z;

      if (overlapX < overlapZ) {
        if (position.x < p.position.x) {
          position.x = pMin.x - r - 0.01;
        } else {
          position.x = pMax.x + r + 0.01;
        }
        velocity.x = 0;
      } else {
        if (position.z < p.position.z) {
          position.z = pMin.z - r - 0.01;
        } else {
          position.z = pMax.z + r + 0.01;
        }
        velocity.z = 0;
      }
    }
  }

  void takeDamage() {
    lives--;
    position = checkpoint.clone();
    velocity = Vector3.zero();
    isGroundPounding = false;
    if (lives < 0) lives = 0;
  }

  void collectCoin() {
    coins++;
    score += 100;
  }

  void bounce() {
    velocity.y = GameConstants.jumpForce * 0.7;
    isGrounded = false;
  }

  void setCheckpoint(Vector3 cp) {
    checkpoint = cp.clone();
  }

  static double lerpDouble(double a, double b, double t) {
    return a + (b - a) * t.clamp(0.0, 1.0);
  }
}