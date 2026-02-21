import 'package:briscola/game/components/deck_pile.dart';
import 'package:briscola/game/components/hand.dart';

class DrawCardCommand {
  final DeckPile _deck;
  final void Function(Hand) _action;

  DrawCardCommand(this._deck, this._action);

  void execute(Hand hand) {
    if (!_deck.isEmpty) return;
    _action(hand);
  }
}