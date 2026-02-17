import 'dart:async';
import 'dart:ui';

import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/tricks_pile.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

enum PlayerType { local, remote }

class PlayingSurface extends PositionComponent {
  final Map<PlayerType, Card?> _slots = {
    PlayerType.local: null,
    PlayerType.remote: null,
  };

  static final Paint backgroundPaint = Paint()..color = const Color(0xffffd700);
  static final Paint innerBackgroundPaint = Paint()
    ..color = const Color(0xff990030);

  static final RRect surfaceRRect = RRect.fromRectAndRadius(
    BriscolaWorld.surfaceSize.toRect(),
    const Radius.circular(BriscolaWorld.cardRadius),
  );

  static final RRect innerSurfaceRRect = surfaceRRect.deflate(3);

  void acquireCard(Card card, PlayerType type) {
    Vector2 cardPosition =
        position +
        Vector2(BriscolaWorld.surfacePadding, BriscolaWorld.surfacePadding);
    if (type == PlayerType.remote) {
      assert(card.isFaceUp == false);
      cardPosition += Vector2(
        BriscolaWorld.cardWidth + BriscolaWorld.cardGap,
        0.0,
      );
      card.flip();
    }
    card.position = cardPosition;
    _slots[type] = card;
  }

  Future<void> moveCardsTo(TricksPile pile) async {
    assert(
      _slots[PlayerType.local] != null && _slots[PlayerType.remote] != null,
    );

    final completer = Completer();

    Card playerCard = _slots[PlayerType.local]!;
    Card opponentCard = _slots[PlayerType.remote]!;

    addMoveEffectToCard(playerCard, pile.position, () {
      pile.acquireCard(playerCard);
      _slots[PlayerType.local] = null;
      if (_slots.values.every((card) => card == null)) {
        completer.complete();
      }
    });

    addMoveEffectToCard(opponentCard, pile.position, () {
      pile.acquireCard(opponentCard);
      _slots[PlayerType.remote] = null;
      if (_slots.values.every((card) => card == null)) {
        completer.complete();
      }
    });

    return completer.future;
  }

  void addMoveEffectToCard(Card card, Vector2 to, VoidCallback onComplete) {
    final dt = (to - card.position).length / (10.0 * card.width);
    card.add(
      MoveToEffect(
        to,
        EffectController(
          duration: dt,
          startDelay: 1.25,
          curve: Curves.easeOutQuad,
        ),
        onComplete: onComplete,
      ),
    );
  }

  Card? get playerCard => _slots[PlayerType.local];

  Card? get opponentCard => _slots[PlayerType.remote];

  bool canAcquireCard(PlayerType type) => _slots[type] == null;

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(surfaceRRect, backgroundPaint);
    canvas.drawRRect(innerSurfaceRRect, innerBackgroundPaint);
  }
}
