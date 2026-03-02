import 'dart:developer';

import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/hand.dart';

class PlayerHand extends Hand {
  void Function(Card)? onPlayCard;

  PlayerHand(super.type);

  @override
  void acquireCard(Card card) {
    card.handleTap = _playCard;
    card.flip();
    super.acquireCard(card);
  }

  @override
  Card removeCard(Card card) {
    final removedCard = super.removeCard(card);
    removedCard.handleTap = null;
    return removedCard;
  }

  void _playCard(Card card) {
    if (!isEnabled) return;
    log('playing card and enabled = ${isEnabled.toString()}');
    onPlayCard?.call(card);
  }
}
