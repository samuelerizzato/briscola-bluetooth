import 'package:briscola/game/game_result.dart';
import 'package:briscola/game/states/state_machine.dart';

import 'game_state.dart';

class GameOverState implements GameState {
  @override
  void enter(StateMachine stateMachine) {
    stateMachine.context.onGameOver(
        GameResult(
          stateMachine.context.playerTricksPile.countPoints(),
          stateMachine.context.opponentTricksPile.countPoints(),
        )
    );
  }

  @override
  void exit(StateMachine stateMachine) {}
}