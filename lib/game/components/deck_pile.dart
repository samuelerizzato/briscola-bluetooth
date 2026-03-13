import 'dart:async';

import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/card_holder.dart';
import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/states/game_state.dart';
import 'package:briscola/game/states/state_machine.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

class DeckPile extends PositionComponent
    with TapCallbacks
    implements CardHolder {
  final List<Card> _cards = [];
  bool _isEnabled = false;
  void Function()? onDrawCard;

  bool get isEmpty => _cards.isEmpty;

  Card get topCard => _cards.last;

  final StreamController<void> _deckChangesController =
      StreamController<void>.broadcast();

  Stream<void> get deckChanges => _deckChangesController.stream;

  @override
  void acquireCard(Card card) {
    card.position = position;
    card.priority = _cards.length + 1;
    _cards.add(card);
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_cards.isEmpty || !_isEnabled) return;
    onDrawCard?.call();
  }

  void onGameStateChanged(GameState state) {
    _isEnabled =
        state.phase == GamePhase.draw &&
        state.currentHand.type == PlayerType.local;
  }

  void setBriscola(int index) {
    assert(_cards.isNotEmpty && index < _cards.length && index >= 0);
    Card briscola = _cards[index];
    int priority = briscola.priority;
    briscola.priority = _cards.first.priority;
    _cards.first.priority = priority;
    _cards[index] = _cards.first;
    _cards.first = briscola;
    briscola.position = Vector2(
      x + BriscolaWorld.cardWidth / 2.0,
      y + (BriscolaWorld.cardWidth + BriscolaWorld.cardHeight) / 2.0,
    );
    briscola.angle += radians(-90);
    briscola.flip();
  }

  @override
  Card removeCard(Card card) {
    if (_cards.last.rank.value != card.rank.value ||
        _cards.last.suit.type != card.suit.type) {
      throw StateError(
        'Cannot remove card ${card.rank} ${card.suit.type} because is not on top',
      );
    }

    Card topCard = _cards.removeLast();
    if (_cards.length == 1) {
      _cards.first.flip();
      _cards.first.position = position;
      _cards.first.angle = 0;
    }
    _deckChangesController.add(null);
    return topCard;
  }
}
