import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState {
  idle,
  running,
  jumping,
  doubleJumping,
  falling,
  climbing,
}

enum PlayerDirection {
  left,
  right,
  none,
}

class Player extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, KeyboardHandler {
  final String character;
  Player({position, this.character = 'Mask Dude'}) : super(position: position);
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation doubleJumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation climbingAnimation;
  final double stepTime = 0.05;

  PlayerDirection playerDirection = PlayerDirection.none;
  double moveSpeed = 100;
  Vector2 velocity = Vector2.zero();
  bool isFacingRight = true;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Atualize o movimento baseado na direção do joystick
    if (gameRef.joystick.direction != JoystickDirection.idle) {
      // Atualize a direção e posição com base na entrada do joystick, mantendo apenas o movimento horizontal
      final Vector2 direction =
          Vector2(gameRef.joystick.relativeDelta.x, 0) * moveSpeed;
      position.add(direction * dt);

      // Atualize a direção do jogador com base no movimento horizontal
      if (direction.x > 0) {
        playerDirection = PlayerDirection.right;
        if (!isFacingRight) {
          flipHorizontallyAroundCenter();
          isFacingRight = true;
        }
      } else if (direction.x < 0) {
        playerDirection = PlayerDirection.left;
        if (isFacingRight) {
          flipHorizontallyAroundCenter();
          isFacingRight = false;
        }
      } else {
        playerDirection = PlayerDirection.none;
      }
    } else {
      playerDirection = PlayerDirection
          .none; // Define como parado quando o joystick está em idle
    }

    // Atualiza o movimento e o estado do jogador
    _updatePlayerMovement(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD);
    final isUpKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyW);
    final isDownKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyS);

    if (!isLeftKeyPressed && !isRightKeyPressed) {
      playerDirection = PlayerDirection.none;
    } else if (isLeftKeyPressed) {
      playerDirection = PlayerDirection.left;
    } else if (isRightKeyPressed) {
      playerDirection = PlayerDirection.right;
    } else {
      playerDirection = PlayerDirection.none;
    }

    return super.onKeyEvent(event, keysPressed);
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
        game.images
            .fromCache('Main Characters/${character}/${state} (32x32).png'),
        SpriteAnimationData.sequenced(
          amount: amount,
          stepTime: stepTime,
          textureSize: Vector2.all(32),
        ));
  }

  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation("Idle", 11);
    runningAnimation = _spriteAnimation("Run", 12);
    jumpingAnimation = _spriteAnimation("Jump", 1);
    doubleJumpingAnimation = _spriteAnimation("Double Jump", 6);
    fallingAnimation = _spriteAnimation("Fall", 1);
    climbingAnimation = _spriteAnimation("Wall Jump", 5);

    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.doubleJumping: doubleJumpingAnimation,
      PlayerState.falling: fallingAnimation,
      PlayerState.climbing: climbingAnimation,
    };

    // Set current animation
    current = PlayerState.running;
  }

  void _updatePlayerMovement(double dt) {
    double dirX = 0.0;

    // Atualize a direção e o estado com base na direção atual do jogador
    switch (playerDirection) {
      case PlayerDirection.left:
        dirX = -moveSpeed;
        current = PlayerState.running;
        break;
      case PlayerDirection.right:
        dirX = moveSpeed;
        current = PlayerState.running;
        break;
      case PlayerDirection.none:
        current = PlayerState.idle;
        break;
    }

    velocity = Vector2(dirX, 0.0);
    position += velocity * dt;

    // Se o jogador estiver parado, defina o estado como idle
    if (velocity.x == 0) {
      current = PlayerState.idle;
    }
  }
}
