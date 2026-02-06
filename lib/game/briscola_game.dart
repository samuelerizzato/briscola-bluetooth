import 'dart:async';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';

class BriscolaGame extends FlameGame {
  final World _world;

  BriscolaGame(this._world);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(_world);
    camera.world = _world;
  }

  @override
  Color backgroundColor() => const Color(0xFF006400);
}

Sprite briscolaSprite(
  String filename,
  double x,
  double y,
  double width,
  double height,
) => Sprite(
  Flame.images.fromCache(filename),
  srcPosition: Vector2(x, y),
  srcSize: Vector2(width, height),
);
