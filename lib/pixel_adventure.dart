import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'package:pixel_adventure/actors/player.dart';
import 'package:pixel_adventure/levels/level.dart';

class PixelAdventure extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks {
  @override
  Color backgroundColor() => const Color(0xFF211F30);

  late final CameraComponent cam;
  Player player = Player(character: "Mask Dude");
  late JoystickComponent joystick;
  bool showJoystick = true;

  @override
  FutureOr<void> onLoad() async {
    // load all images into cache
    await images.loadAllImages();

    final world = Level(
      levelName: "level_02",
      player: player,
    );

    cam = CameraComponent.withFixedResolution(
        world: world, width: 640, height: 368);
    cam.viewfinder.anchor = Anchor.topLeft;
    addAll([cam, world]);

    if (showJoystick) {
      addJoystick();
    }
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (showJoystick) {
      updateJoystick();
    }
    super.update(dt);
  }

  void addJoystick() {
    joystick = JoystickComponent(
      knob: SpriteComponent(
        sprite: Sprite(images.fromCache('HUD/simple_button.png')),
        scale: Vector2(0.05, 0.05),
      ),
      background: SpriteComponent(
          sprite: Sprite(images.fromCache('HUD/bkg.png')),
          size: Vector2(50, 50)),
      margin: const EdgeInsets.only(left: 32, bottom: 32),
    );
    add(joystick);
  }

  void updateJoystick() {
    if (joystick.isDragged) {
      switch (joystick.direction) {
        case JoystickDirection.left:
          player.playerDirection = PlayerDirection.left;
          break;
        case JoystickDirection.right:
          player.playerDirection = PlayerDirection.right;
          break;
        default:
          player.playerDirection = PlayerDirection.none;
      }
    } else {
      player.playerDirection = PlayerDirection.none;
    }
  }
}
