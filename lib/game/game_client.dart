import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/hand.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/states/game_context.dart';

class GameClient {
  final BriscolaWorld _world;
  final GameContext _context;

  GameClient(this._context, this._world);

  Future<void> applyPlayCard(Hand hand, Card card) =>
      _world.applyPlayCard(hand, card);

  void applyDrawCard(Hand hand) {
    _world.applyDrawCard(hand);
  }

  Hand getHandByType(PlayerType type) =>
      type == PlayerType.local ? _context.playerHand : _context.opponentHand;
}
