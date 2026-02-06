import 'package:briscola/game/states/game_state.dart';
import 'package:briscola/game/states/state_machine.dart';


class OpponentTurnState implements GameState {
  @override
  void enter(StateMachine stateMachine) {
    stateMachine.context.opponentHand.isEnabled = true;
    stateMachine.context.opponentTricksPile.isActive = true;
  }

  @override
  void exit(StateMachine stateMachine) {
    stateMachine.context.opponentHand.isEnabled = false;
    stateMachine.context.opponentTricksPile.isActive = false;
  }
}