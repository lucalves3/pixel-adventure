import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/components/collision_block_platform/collision_block_platform.dart';
import 'package:pixel_adventure/components/player/player_hitbox/player_hitbox.dart';
import 'package:pixel_adventure/pixel_adventure.dart';
import 'package:pixel_adventure/utils/utils.dart';

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
  Player({
    position,
    this.character = 'Mask Dude',
  }) : super(position: position);
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation doubleJumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation climbingAnimation;
  final double stepTime = 0.05;
  final double _gravity = 9.8;
  final double _jumpForce = 200;
  final double _terminalVelocity = 300;
  bool isOnGround = false;
  bool hasJumped = false;
  bool hasDoubleJumped = false;
  bool twoTimesSpaceWasPressed = false;
  PlayerDirection playerDirection = PlayerDirection.none;
  double horizontalMovement = 0;
  double moveSpeed = 100;
  Vector2 velocity = Vector2.zero();
  List<CollisionBlock> collisionBlocks = [];
  PlayerHitbox hitbox = PlayerHitbox(
    offsetX: 10,
    offsetY: 4,
    width: 14,
    height: 28,
  );
  bool isFacingRight = true;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();
    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
    ));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _updatePlayerState(dt);
    _updatePlayerMovement(dt);
    _checkHorizontalCollisions();
    _applyGravity(dt);
    _checkVerticalCollisions();
    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD);
    final isUpKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyW);
    final isDownKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyS);
    final howManyTimesSpaceWasPressed =
        keysPressed.where((key) => key == LogicalKeyboardKey.space).length;
    hasJumped = keysPressed.contains(LogicalKeyboardKey.space);
    hasDoubleJumped = keysPressed.contains(LogicalKeyboardKey.space);
    if (howManyTimesSpaceWasPressed == 2) {
      hasDoubleJumped = true;
    } else {
      hasDoubleJumped = false;
    }

    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;

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

  void _updatePlayerState(double dt) {
    PlayerState playerState = PlayerState.idle;

    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    if (velocity.x > 0 || velocity.x < 0) {
      playerState = PlayerState.running;
    }

    current = playerState;
  }

  void _updatePlayerMovement(double dt) {
    velocity.x = horizontalMovement * moveSpeed;
    position += velocity * dt;
    if (hasJumped && isOnGround) _playerJump(dt);
    if (velocity.y < 0) current = PlayerState.jumping;

    // check is falling
    if (velocity.y > 0) {
      current = PlayerState.falling;
    }
    //   double dirX = 0.0;

    //   // Atualize a direção e o estado com base na direção atual do jogador
    //   switch (playerDirection) {
    //     case PlayerDirection.left:
    //       dirX = -moveSpeed;
    //       current = PlayerState.running;
    //       break;
    //     case PlayerDirection.right:
    //       dirX = moveSpeed;
    //       current = PlayerState.running;
    //       break;
    //     case PlayerDirection.none:
    //       current = PlayerState.idle;
    //       break;
    //   }

    //   velocity = Vector2(dirX, 0.0);
    //   position += velocity * dt;

    //   // Se o jogador estiver parado, defina o estado como idle
    //   if (velocity.x == 0) {
    //     current = PlayerState.idle;
    //   }
    // }
  }

  void _playerJump(double dt) {
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    isOnGround = false;
    hasJumped = false;
  }

  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      if (!block.isPlatform) {
        if (checkCollision(this, block)) {
          // Verifique a direção e ajuste a posição corretamente
          if (velocity.x > 0) {
            // Movendo para a direita
            velocity.x = 0;
            position.x = block.x -
                hitbox.offsetX -
                hitbox.width; // Ajuste a posição com base na largura do jogador
            break;
          } else if (velocity.x < 0) {
            // Movendo para a esquerda
            velocity.x = 0;
            position.x = block.x +
                block.width +
                hitbox.offsetX +
                hitbox.width; // Ajuste a posição com base na largura do bloco
            break;
          }
        }
      }
    }
  }

  void _applyGravity(double dt) {
    velocity.y += _gravity;
    velocity.y - velocity.y.clamp(-_jumpForce, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
      if (block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
        }
      } else if (checkCollision(this, block)) {
        if (velocity.y > 0) {
          velocity.y = 0;
          position.y = block.y - hitbox.height - hitbox.offsetY;
          isOnGround = true;
          break;
        } else if (velocity.y < 0) {
          velocity.y = 0;
          position.y = block.y + block.height + hitbox.offsetY;
          isOnGround = false;
          break;
        }
      }
    }
  }
}
