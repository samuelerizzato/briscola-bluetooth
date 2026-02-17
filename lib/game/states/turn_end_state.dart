import 'dart:developer';

import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/components/tricks_pile.dart';
import 'package:briscola/game/states/game_state.dart';
import 'package:briscola/game/states/state_machine.dart';
import 'package:briscola/game/suit.dart';

import 'game_context.dart';

class TurnEndState implements GameState {
  @override
  Future<void> enter(StateMachine stateMachine) async {
    log('entered turn end state');
    GameContext ctx = stateMachine.context;
    PlayingSurface surface = ctx.playingSurface;

    if (surface.canAcquireCard(PlayerType.local)) {
      stateMachine.transitionTo(stateMachine.playerTurnState);
      return;
    }

    if (surface.canAcquireCard(PlayerType.remote)) {
      stateMachine.transitionTo(stateMachine.opponentTurnState);
      return;
    }

    PlayerType winner = _decideTurnWinner(
      surface.playerCard!,
      surface.opponentCard!,
      ctx.briscolaSuit,
      ctx.leadPlayer,
    );

    ctx.leadPlayer = winner;
    TricksPile winnerPile = winner == PlayerType.local
        ? ctx.playerTricksPile
        : ctx.opponentTricksPile;

    await surface.moveCardsTo(winnerPile);
    return stateMachine.transitionTo(stateMachine.decideState);
  }

  PlayerType _decideTurnWinner(
    Card playerCard,
    Card opponentCard,
    SuitType briscolaSuit,
    PlayerType leadPlayer,
  ) {
    if (playerCard.suit.type == opponentCard.suit.type) {
      return playerCard.rank.compareTo(opponentCard.rank) > 0
          ? PlayerType.local
          : PlayerType.remote;
    }

    if (playerCard.suit.type == briscolaSuit) {
      return PlayerType.local;
    }

    if (opponentCard.suit.type == briscolaSuit) {
      return PlayerType.remote;
    }

    return leadPlayer;
  }

  @override
  Future<void> exit(StateMachine stateMachine) async {}
}
