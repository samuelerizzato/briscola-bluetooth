import 'package:briscola/game/briscola_game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';

enum SuitType { batons, coins, cups, swords }

@immutable
class Suit {
  factory Suit.fromType(SuitType type) {
    return _types[type]!;
  }

  final Sprite sprite;
  final SuitType type;

  const Suit._(this.sprite, this.type);

  static final Map<SuitType, Suit> _types = {
    SuitType.batons: Suit._(
      briscolaSprite('baton.png', 40.0, 17.0, 20.0, 66.0),
      SuitType.batons,
    ),
    SuitType.coins: Suit._(
      briscolaSprite('coin.png', 29.0, 29.0, 41.0, 41.0),
      SuitType.coins,
    ),
    SuitType.cups: Suit._(
      briscolaSprite('cup.png', 29.0, 36.0, 41.0, 34.0),
      SuitType.cups,
    ),
    SuitType.swords: Suit._(
      briscolaSprite('sword.png', 33.0, 18.0, 33.0, 65.0),
      SuitType.swords,
    ),
  };
}
