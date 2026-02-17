import 'package:briscola/game/states/game_state.dart';

import 'state_machine.dart';

class PlayerDrawState implements GameState {
  @override
  Future<void> enter(StateMachine stateMachine) async {
    stateMachine.context.deck.isEnabled = true;
    stateMachine.context.playerTricksPile.isActive = true;
  }

  @override
  Future<void> exit(StateMachine stateMachine) async {
    stateMachine.context.deck.isEnabled = false;
    stateMachine.context.playerTricksPile.isActive = false;
  }
}