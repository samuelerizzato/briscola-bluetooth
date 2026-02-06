import 'dart:ui';

import 'package:briscola/game/briscola_game.dart';
import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/rank.dart';
import 'package:briscola/game/suit.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

class Card extends PositionComponent with TapCallbacks {
  bool _faceUp;
  final Suit suit;
  final Rank rank;
  void Function(Card card)? handleTap;

  static final RRect cardRRect = RRect.fromRectAndRadius(
    BriscolaWorld.cardSize.toRect(),
    const Radius.circular(BriscolaWorld.cardRadius),
  );

  static final RRect backRRectInner = cardRRect.deflate(5);

  static final Paint frontBackgroundPaint = Paint()
    ..color = const Color(0xffffffff);

  static final Paint backBackgroundPaint = Paint()
    ..color = const Color(0xffffffff);
  static final Paint backInnerBackgroundPaint = Paint()
    ..color = const Color(0xff990030);

  static final Sprite jackSprite = briscolaSprite(
    'jack.png',
    13.0,
    32.0,
    72.0,
    34.0,
  );
  static final Sprite knightSprite = briscolaSprite(
    'knight.png',
    25.0,
    19.0,
    50.0,
    61.0,
  );
  static final Sprite kingSprite = briscolaSprite(
    'king.png',
    17.0,
    25.0,
    65.0,
    49.0,
  );

  Card(int rank, SuitType suitType)
    : _faceUp = false,
      rank = Rank.fromInt(rank),
      suit = Suit.fromType(suitType),
      super(size: BriscolaWorld.cardSize);

  bool get isFaceUp => _faceUp;

  @override
  void render(Canvas canvas) {
    if (_faceUp) {
      _renderFront(canvas);
    } else {
      _renderBack(canvas);
    }
  }

  void flip() {
    _faceUp = !_faceUp;
  }

  void _renderFront(Canvas canvas) {
    canvas.drawRRect(cardRRect, frontBackgroundPaint);

    switch (rank) {
      case Rank.ace:
        _drawSprite(
          canvas,
          suit.sprite,
          Vector2(width / 2, height / 2),
          scale: 1.7,
        );
        break;
      case Rank.two:
        Vector2 distance = _computeDistanceFromBorders(suit.sprite.srcSize);
        _drawSprite(canvas, suit.sprite, distance);
        _drawSprite(canvas, suit.sprite, size - distance);
        break;
      case Rank.three:
        Vector2 distance = _computeDistanceFromBorders(suit.sprite.srcSize);
        _drawSprite(canvas, suit.sprite, distance);
        _drawSprite(canvas, suit.sprite, Vector2(width / 2, height / 2));
        _drawSprite(canvas, suit.sprite, size - distance);
        break;
      case Rank.four:
        Vector2 distance = _computeDistanceFromBorders(
          suit.sprite.srcSize,
          scale: 0.8,
        );
        _drawSprite(canvas, suit.sprite, distance, scale: 0.8);
        _drawSprite(
          canvas,
          suit.sprite,
          Vector2(width - distance.x, distance.y),
          scale: 0.8,
        );
        _drawSprite(
          canvas,
          suit.sprite,
          Vector2(distance.x, height - distance.y),
          scale: 0.8,
        );
        _drawSprite(canvas, suit.sprite, size - distance, scale: 0.8);
        break;
      case Rank.five:
        Vector2 distance = _computeDistanceFromBorders(
          suit.sprite.srcSize,
          scale: 0.8,
        );
        _drawSprite(canvas, suit.sprite, distance, scale: 0.8);
        _drawSprite(
          canvas,
          suit.sprite,
          Vector2(width - distance.x, distance.y),
          scale: 0.8,
        );
        _drawSprite(
          canvas,
          suit.sprite,
          Vector2(width / 2, height / 2),
          scale: 0.8,
        );
        _drawSprite(
          canvas,
          suit.sprite,
          Vector2(distance.x, height - distance.y),
          scale: 0.8,
        );
        _drawSprite(canvas, suit.sprite, size - distance, scale: 0.8);
        break;
      case Rank.six:
        Vector2 distance = _computeDistanceFromBorders(
          suit.sprite.srcSize,
          scale: 0.7,
        );
        _drawSprite(canvas, suit.sprite, distance, scale: 0.7);
        _drawSprite(
          canvas,
          suit.sprite,
          Vector2(width - distance.x, distance.y),
          scale: 0.7,
        );
        _drawSprite(
          canvas,
          suit.sprite,
          Vector2(distance.x, height / 2.0),
          scale: 0.7,
        );
        _drawSprite(
          canvas,
          suit.sprite,
          Vector2(width - distance.x, height / 2.0),
          scale: 0.7,
        );
        _drawSprite(
          canvas,
          suit.sprite,
          Vector2(distance.x, height - distance.y),
          scale: 0.7,
        );
        _drawSprite(canvas, suit.sprite, size - distance, scale: 0.7);
        break;
      case Rank.seven:
        Vector2 distance = _computeDistanceFromBorders(
          suit.sprite.srcSize,
          scale: 0.6,
        );
        _drawSprite(canvas, suit.sprite, distance, scale: 0.6);
        _drawSprite(
          canvas,
          suit.sprite,
          Vector2(width - distance.x, distance.y),
          scale: 0.6,
        );
        _drawSprite(
          canvas,
          suit.sprite,
          Vector2(distance.x, height / 2.0),
          scale: 0.6,
        );
        _drawSprite(
          canvas,
          suit.sprite,
          Vector2(width - distance.x, height / 2.0),
          scale: 0.6,
        );
        _drawSprite(
          canvas,
          suit.sprite,
          Vector2(distance.x, height - distance.y),
          scale: 0.6,
        );
        _drawSprite(
          canvas,
          suit.sprite,
          Vector2(width / 2.0, height - distance.y),
          scale: 0.6,
        );
        _drawSprite(canvas, suit.sprite, size - distance, scale: 0.6);
        break;
      case Rank.jack:
        _drawFigureSprite(canvas, suit.sprite, jackSprite);
        break;
      case Rank.knight:
        _drawFigureSprite(canvas, suit.sprite, knightSprite);
        break;
      case Rank.king:
        _drawFigureSprite(canvas, suit.sprite, kingSprite);
        break;
    }
  }

  Vector2 _computeDistanceFromBorders(Vector2 size, {double scale = 1.0}) {
    Vector2 scaledSize = size.scaled(scale);
    return Vector2(scaledSize.x / 2.0 + 5.0, scaledSize.y / 2.0 + 5.0);
  }

  void _drawFigureSprite(
    Canvas canvas,
    Sprite suitSprite,
    Sprite figureSprite,
  ) {
    double scale = 0.7;
    Vector2 distance = _computeDistanceFromBorders(
      suit.sprite.srcSize,
      scale: scale,
    );
    _drawSprite(canvas, suit.sprite, distance, scale: scale);
    _drawSprite(
      canvas,
      suit.sprite,
      Vector2(width - distance.x, distance.y),
      scale: scale,
    );
    _drawSprite(
      canvas,
      suit.sprite,
      Vector2(distance.x, height - distance.y),
      scale: scale,
    );
    _drawSprite(canvas, suit.sprite, size - distance, scale: scale);
    _drawSprite(canvas, figureSprite, Vector2(width / 2, height / 2));
  }

  void _drawSprite(
    Canvas canvas,
    Sprite suitSprite,
    Vector2 position, {
    double scale = 1.0,
  }) {
    suitSprite.render(
      canvas,
      position: position,
      size: suitSprite.srcSize.scaled(scale),
      anchor: Anchor.center,
    );
  }

  void _renderBack(Canvas canvas) {
    canvas.drawRRect(cardRRect, backBackgroundPaint);
    canvas.drawRRect(backRRectInner, backInnerBackgroundPaint);
  }

  @override
  void onTapUp(TapUpEvent event) {
    handleTap?.call(this);
  }
}
