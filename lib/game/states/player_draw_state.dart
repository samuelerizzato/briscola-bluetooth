import 'package:briscola/game/states/game_state.dart';

import 'state_machine.dart';

class PlayerDrawState implements GameState {
  @override
  void enter(StateMachine stateMachine) {
    stateMachine.context.deck.isEnabled = true;
    stateMachine.context.playerTricksPile.isActive = true;
  }

  @override
  void exit(StateMachine stateMachine) {
    stateMachine.context.deck.isEnabled = false;
    stateMachine.context.playerTricksPile.isActive = false;
  }
}