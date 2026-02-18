import 'package:briscola/game/game_result.dart';
import 'package:briscola/game/states/state_machine.dart';

import 'game_state.dart';

class GameOverState implements GameState {
  @override
  Future<void> enter(StateMachine stateMachine) async {
    int playerPoints = stateMachine.context.playerTricksPile.countPoints();
    int opponentPoints = stateMachine.context.opponentTricksPile.countPoints();

    stateMachine.context.onGameOver(
      GameResult(
        playerPoints > opponentPoints
            ? GameOutcome.win
            : playerPoints < opponentPoints
            ? GameOutcome.loss
            : GameOutcome.draw,
        points: playerPoints,
        opponentPoints: opponentPoints,
      ),
    );
  }

  @override
  Future<void> exit(StateMachine stateMachine) async {}
}
