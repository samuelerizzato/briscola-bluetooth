import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/hand.dart';
import 'package:briscola/game/states/game_context.dart';

class GameServer {
  final BriscolaWorld _world;
  final GameContext _context;

  GameServer(this._world, this._context);

  bool applyPlayCard(Hand hand, Card card) {
    final surface = _context.playingSurface;
    if (hand.isEnabled && surface.canAcquireCard(hand.type)) {
      _world.applyPlayCard(hand, card);
      return true;
    }
    return false;
  }

  bool applyDrawCard(Hand hand) {
    if (_context.deck.isEmpty) return false;
    _world.applyDrawCard(hand);
    return true;
  }

  Hand get playerHand => _context.playerHand;
  Hand get opponentHand => _context.opponentHand;
}