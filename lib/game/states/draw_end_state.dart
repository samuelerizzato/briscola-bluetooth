import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/states/game_context.dart';
import 'package:briscola/game/states/game_state.dart';
import 'package:briscola/game/states/state_machine.dart';

class DrawEndState implements GameState {
  @override
  Future<void> enter(StateMachine stateMachine) {
    GameState nextState;
    GameContext context = stateMachine.context;

    if (context.leadPlayer == PlayerType.local) {
      nextState = context.opponentHand.canAcquireCard()
          ? stateMachine.opponentDrawState
          : stateMachine.playerTurnState;
    } else {
      nextState = context.playerHand.canAcquireCard()
          ? stateMachine.playerDrawState
          : stateMachine.opponentTurnState;
    }

    return stateMachine.transitionTo(nextState);
  }

  @override
  Future<void> exit(StateMachine stateMachine) async {}
}
