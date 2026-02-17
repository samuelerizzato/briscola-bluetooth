import 'package:briscola/game/game_result.dart';
import 'package:briscola/game/states/state_machine.dart';

import 'game_state.dart';

class GameOverState implements GameState {
  @override
  Future<void> enter(StateMachine stateMachine) async {
    stateMachine.context.onGameOver(
        GameResult(
          false,
          stateMachine.context.playerTricksPile.countPoints(),
          stateMachine.context.opponentTricksPile.countPoints(),
        )
    );
  }

  @override
  Future<void> exit(StateMachine stateMachine) async {}
}