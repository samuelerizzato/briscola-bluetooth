import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/hand.dart';
import 'package:briscola/game/components/playing_surface.dart';

class PlayCardCommand {
  final PlayingSurface _surface;
  final Future<void> Function(Hand, Card) _action;

  PlayCardCommand(this._surface, this._action);

  void execute(Hand hand, Card card) {
      if (hand.isEnabled && _surface.canAcquireCard(hand.type)) return;
      _action(hand, card);
  }
}