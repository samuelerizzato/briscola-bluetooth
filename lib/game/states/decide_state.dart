import 'dart:developer';

import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/states/game_state.dart';
import 'package:briscola/game/states/state_machine.dart';

import 'game_context.dart';

class DecideState implements GameState {
  @override
  Future<void> enter(StateMachine stateMachine) async {
    GameContext ctx = stateMachine.context;
    GameState nextState;

    if (ctx.playerHand.isEmpty) {
      nextState = stateMachine.gameOverState;
    } else if (ctx.deck.isEmpty) {
      nextState = ctx.leadPlayer == PlayerType.local
          ? stateMachine.playerTurnState
          : stateMachine.opponentTurnState;
    } else {
      nextState = ctx.leadPlayer == PlayerType.local
          ? stateMachine.playerDrawState
          : stateMachine.opponentDrawState;
    }
    log('entered decide state');
    return stateMachine.transitionTo(nextState);
  }

  @override
  Future<void> exit(StateMachine stateMachine) async {}
}
