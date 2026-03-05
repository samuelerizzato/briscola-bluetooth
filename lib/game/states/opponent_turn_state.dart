import 'package:briscola/game/states/game_context.dart';
import 'package:briscola/game/states/game_state.dart';
import 'package:briscola/game/states/state_machine.dart';


class OpponentTurnState implements GameState {
  @override
  Future<void> enter(StateMachine stateMachine) async {
    GameContext context = stateMachine.context;
    context.opponentHand.isEnabled = true;
    context.opponentTricksPile.isActive = true;
    context.playingSurface.setActiveSlot(context.opponentHand.type);
  }

  @override
  Future<void> exit(StateMachine stateMachine) async {
    stateMachine.context.opponentHand.isEnabled = false;
    stateMachine.context.opponentTricksPile.isActive = false;
  }
}