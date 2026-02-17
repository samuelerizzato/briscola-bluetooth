import 'package:briscola/game/states/game_state.dart';
import 'package:briscola/game/states/state_machine.dart';


class OpponentTurnState implements GameState {
  @override
  Future<void> enter(StateMachine stateMachine) async {
    stateMachine.context.opponentHand.isEnabled = true;
    stateMachine.context.opponentTricksPile.isActive = true;
  }

  @override
  Future<void> exit(StateMachine stateMachine) async {
    stateMachine.context.opponentHand.isEnabled = false;
    stateMachine.context.opponentTricksPile.isActive = false;
  }
}