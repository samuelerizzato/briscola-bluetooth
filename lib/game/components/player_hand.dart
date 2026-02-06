import 'dart:developer';

import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/hand.dart';
import 'package:flame/components.dart';

class PlayerHand extends Hand with HasWorldReference<BriscolaWorld> {
  PlayerHand(super.type);

  @override
  void acquireCard(Card card) {
    card.handleTap = _playCard;
    card.flip();
    super.acquireCard(card);
  }

  @override
  void removeCard(Card card) {
    card.handleTap = null;
    super.removeCard(card);
  }

  void _playCard(Card card) {
    if (!isEnabled) return;
    log('playing card and enabled = ${isEnabled.toString()}');
    world.onLocalPlayCard(card);
  }
}
