import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:flame/components.dart';

class Hand extends PositionComponent {
  final List<Card> _cards = [];
  final PlayerType _type;
  bool isEnabled = false;

  Hand(this._type);

  List<Card> get cards => List.unmodifiable(_cards);

  bool get isEmpty => _cards.isEmpty;

  PlayerType get type => _type;

  int get maxSize => 3;

  void acquireCard(Card card) {
    double cardSpace = BriscolaWorld.cardWidth + BriscolaWorld.cardGap;
    card.position = position + Vector2(cardSpace * _cards.length, 0.0);
    card.priority = 0;
    card.angle = 0;
    _cards.add(card);
  }

  void removeCard(Card card) {
    int cardIndex = _cards.indexWhere(
      (c) => c.rank.value == card.rank.value && c.suit.type == card.suit.type,
    );
    _cards.removeAt(cardIndex);
    for (var i = cardIndex; i < _cards.length; i++) {
      _cards[i].position.sub(
        Vector2(BriscolaWorld.cardWidth + BriscolaWorld.cardGap, 0.0),
      );
    }
  }

  bool canAcquireCard() => _cards.length < 3;
}
