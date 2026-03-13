import 'dart:ui';

import 'package:briscola/game/components/deck_pile.dart';
import 'package:briscola/game/components/hand.dart';
import 'package:briscola/game/components/player_hand.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/components/tricks_pile.dart';
import 'package:briscola/game/suit.dart';

class GameContext {
  final DeckPile deck = DeckPile();
  final PlayingSurface playingSurface = PlayingSurface();
  final PlayerHand playerHand = PlayerHand(PlayerType.local);
  final Hand opponentHand = Hand(PlayerType.remote);
  final TricksPile playerTricksPile = TricksPile(
    Color(0x8834afeb),
    PlayerType.local,
  );
  final TricksPile opponentTricksPile = TricksPile(
    Color(0x88dc232a),
    PlayerType.remote,
  );
  SuitType briscolaSuit = SuitType.batons;
}
