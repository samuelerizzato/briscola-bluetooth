import 'package:briscola/game/states/game_state.dart';

import 'state_machine.dart';

class OpponentDrawState implements GameState {
  @override
  Future<void> enter(StateMachine stateMachine) async {
    stateMachine.context.opponentTricksPile.isActive = true;
  }

  @override
  Future<void> exit(StateMachine stateMachine) async {
    stateMachine.context.opponentTricksPile.isActive = false;
  }
}
