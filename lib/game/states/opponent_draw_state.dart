import 'package:briscola/game/states/game_state.dart';

import 'state_machine.dart';

class OpponentDrawState implements GameState {
  @override
  void enter(StateMachine stateMachine) {
    stateMachine.context.opponentTricksPile.isActive = true;
  }

  @override
  void exit(StateMachine stateMachine) {
    stateMachine.context.opponentTricksPile.isActive = false;
  }
}
