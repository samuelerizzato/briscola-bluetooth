import 'dart:ui';

import 'package:briscola/game/components/deck_pile.dart';
import 'package:briscola/game/components/hand.dart';
import 'package:briscola/game/components/player_hand.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/components/tricks_pile.dart';
import 'package:briscola/game/game_result.dart';
import 'package:briscola/game/suit.dart';

class GameContext {
  final DeckPile deck;
  final PlayingSurface playingSurface;
  final PlayerHand playerHand;
  final Hand opponentHand;
  final TricksPile playerTricksPile;
  final TricksPile opponentTricksPile;

  SuitType briscolaSuit = SuitType.batons;
  PlayerType leadPlayer;

  final void Function(GameResult result) onGameOver;

  GameContext(this.leadPlayer, this.onGameOver)
    : deck = DeckPile(),
      playingSurface = PlayingSurface(),
      playerHand = PlayerHand(PlayerType.local),
      opponentHand = Hand(PlayerType.remote),
      playerTricksPile = TricksPile(Color(0x8834afeb)),
      opponentTricksPile = TricksPile(Color(0x88dc232a));
}
