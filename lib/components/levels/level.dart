import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:pixel_adventure/components/player/player.dart';

class Level extends World {
  final String levelName;
  final Player player;
  late TiledComponent level;

  Level({required this.levelName, required this.player});

  @override
  FutureOr<void> onLoad() async {
    level = await TiledComponent.load('${levelName}.tmx', Vector2.all(16.0));
    final spawnPointsLayer = level.tileMap.getLayer<ObjectGroup>('SpawnPoints');
    final nextMap = level.tileMap.getLayer<ObjectGroup>('NextMap');
    for (final spawnPoint in spawnPointsLayer!.objects) {
      switch (spawnPoint.class_) {
        case "Player":
          final player = Player(
            character: "Mask Dude",
            position: Vector2(spawnPoint.x, spawnPoint.y),
          );
          add(player);
          break;
      }
    }
    add(level);
    return super.onLoad();
  }
}
