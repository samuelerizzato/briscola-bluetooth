import 'package:briscola/game/states/state_machine.dart';

import 'game_state.dart';

class PlayerTurnState implements GameState {
  @override
  Future<void> enter(StateMachine stateMachine) async {
    stateMachine.context.playerHand.isEnabled = true;
    stateMachine.context.playerTricksPile.isActive = true;
  }

  @override
  Future<void> exit(StateMachine stateMachine) async {
    stateMachine.context.playerHand.isEnabled = false;
    stateMachine.context.playerTricksPile.isActive = false;
  }
}