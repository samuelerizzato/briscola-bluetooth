import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/card_holder.dart';
import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/states/game_state.dart';
import 'package:briscola/game/states/state_machine.dart';
import 'package:flame/components.dart';

class Hand extends PositionComponent implements CardHolder {
  final List<Card> _cards = [];
  final PlayerType _type;
  bool isEnabled = false;

  void Function(Card)? onPlayCard;

  Hand(this._type);

  List<Card> get cards => List.unmodifiable(_cards);

  bool get isEmpty => _cards.isEmpty;

  PlayerType get type => _type;

  int get maxSize => 3;

  @override
  void acquireCard(Card card) {
    double cardSpace = BriscolaWorld.cardWidth + BriscolaWorld.cardGap;
    card.position = position + Vector2(cardSpace * _cards.length, 0.0);
    card.priority = 0;
    card.angle = 0;
    card.handleTap = (card) {
      if (!isEnabled) return;
      isEnabled = false;
      onPlayCard?.call(card);
    };
    _cards.add(card);
  }

  @override
  Card removeCard(Card card) {
    int cardIndex = _cards.indexWhere(
      (c) => c.rank.value == card.rank.value && c.suit.type == card.suit.type,
    );
    final removedCard = _cards.removeAt(cardIndex);
    for (var i = cardIndex; i < _cards.length; i++) {
      _cards[i].position.sub(
        Vector2(BriscolaWorld.cardWidth + BriscolaWorld.cardGap, 0.0),
      );
    }
    removedCard.handleTap = null;
    return removedCard;
  }

  void onGameStateChanged(GameState state) {
    isEnabled =
        _type == state.currentHand.type && state.phase == GamePhase.play;
  }

  bool canAcquireCard() => _cards.length < 3;
}
