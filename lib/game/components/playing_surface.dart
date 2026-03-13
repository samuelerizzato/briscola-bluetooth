import 'dart:async';
import 'dart:ui';

import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/card_holder.dart';
import 'package:briscola/game/components/card.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

enum PlayerType { local, remote }

class PlayingSurface extends PositionComponent implements CardHolder {
  final Map<PlayerType, Card?> _slots = {
    PlayerType.local: null,
    PlayerType.remote: null,
  };

  PlayerType _activeSlot = PlayerType.local;

  final StreamController<void> _surfaceChangesController =
    StreamController<void>.broadcast();
  Stream<void> get surfaceChanges => _surfaceChangesController.stream;

  static final Paint backgroundPaint = Paint()..color = const Color(0xffffd700);
  static final Paint innerBackgroundPaint = Paint()
    ..color = const Color(0xff990030);

  static final RRect surfaceRRect = RRect.fromRectAndRadius(
    BriscolaWorld.surfaceSize.toRect(),
    const Radius.circular(BriscolaWorld.cardRadius),
  );

  static final RRect innerSurfaceRRect = surfaceRRect.deflate(3);

  @override
  void acquireCard(Card card) {
    Vector2 cardPosition =
        position +
        Vector2(BriscolaWorld.surfacePadding, BriscolaWorld.surfacePadding);
    if (_activeSlot == PlayerType.remote) {
      assert(card.isFaceUp == false);
      cardPosition += Vector2(
        BriscolaWorld.cardWidth + BriscolaWorld.cardGap,
        0.0,
      );
      card.flip();
    }
    card.position = cardPosition;
    _slots[_activeSlot] = card;
    _surfaceChangesController.add(null);
  }

  void setActiveSlot(PlayerType type) {
    _activeSlot = type;
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

  @override
  void onRemove() {
    _surfaceChangesController.close();
    super.onRemove();
  }

  @override
  Card removeCard(Card card) {
    for (final slot in _slots.entries) {
      if (slot.value?.rank.value == card.rank.value &&
          slot.value?.suit.type == card.suit.type) {
        Card removedCard = _slots[slot.key]!;
        _slots[slot.key] = null;
        return removedCard;
      }
    }
    throw StateError('Could not find card ${card.rank} ${card.suit.type}');
  }
}
