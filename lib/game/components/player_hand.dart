import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/hand.dart';

class PlayerHand extends Hand {
  PlayerHand(super.type);

  @override
  void acquireCard(Card card) {
    card.flip();
    super.acquireCard(card);
  }
}
