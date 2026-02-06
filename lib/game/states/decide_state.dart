import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/states/game_state.dart';
import 'package:briscola/game/states/state_machine.dart';

import 'game_context.dart';

class DecideState implements GameState {
  @override
  void enter(StateMachine stateMachine) {
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

    stateMachine.transitionTo(nextState);
  }

  @override
  void exit(StateMachine stateMachine) {}
}
