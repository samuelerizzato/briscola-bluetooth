import 'package:briscola/game/states/state_machine.dart';

import 'game_state.dart';

class PlayerTurnState implements GameState {
  @override
  void enter(StateMachine stateMachine) {
    stateMachine.context.playerHand.isEnabled = true;
    stateMachine.context.playerTricksPile.isActive = true;
  }

  @override
  void exit(StateMachine stateMachine) {
    stateMachine.context.playerHand.isEnabled = false;
    stateMachine.context.playerTricksPile.isActive = false;
  }
}