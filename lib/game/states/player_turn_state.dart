import 'package:briscola/game/states/game_context.dart';
import 'package:briscola/game/states/state_machine.dart';

import 'game_state.dart';

class PlayerTurnState implements GameState {
  @override
  Future<void> enter(StateMachine stateMachine) async {
    GameContext context = stateMachine.context;
    context.playerHand.isEnabled = true;
    context.playerTricksPile.isActive = true;
    context.playingSurface.setActiveSlot(context.playerHand.type);
  }

  @override
  Future<void> exit(StateMachine stateMachine) async {
    stateMachine.context.playerHand.isEnabled = false;
    stateMachine.context.playerTricksPile.isActive = false;
  }
}