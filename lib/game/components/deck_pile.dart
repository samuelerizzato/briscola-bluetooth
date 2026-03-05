import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/card_holder.dart';
import 'package:briscola/game/components/card.dart';
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

  set isEnabled(bool value) {
    _isEnabled = value;
  }

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

  /*void drawCard(Hand hand) {
    assert(_cards.isNotEmpty);
    if (!hand.canAcquireCard()) return;

    hand.acquireCard(_cards.removeLast());

    if (_cards.length == 1) {
      _cards.first.flip();
      _cards.first.position = position;
      _cards.first.angle = 0;
    }
  }*/

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
    Card topCard = _cards.last;
    if (topCard.rank.value != card.rank.value ||
        topCard.suit.type != card.suit.type) {
      throw StateError('Could not find card ${card.rank} ${card.suit.type}');
    }

    topCard = _cards.removeLast();
    if (_cards.length == 1) {
      _cards.first.flip();
      _cards.first.position = position;
      _cards.first.angle = 0;
    }
    return topCard;
  }
}
