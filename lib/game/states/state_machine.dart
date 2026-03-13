import 'dart:async';

import 'package:briscola/game/game_result.dart';
import 'package:briscola/game/states/game_state.dart';

enum GamePhase {
  initial,
  draw,
  play,
  trickEnd,
  gameOver,
}

class StateMachine {
  GameState? _currentState;

  final StreamController<GameState> _stateChangeController =
      StreamController<GameState>.broadcast();

  Stream<GameState> get stateChanged => _stateChangeController.stream;

  GameState get currentState => _currentState!;

  void Function(GameResult) onGameOver;

  StateMachine(this._currentState, this.onGameOver);

  Future<void> initialize(GameState nextState) async {
    _currentState = nextState;
    _stateChangeController.add(nextState);
  }

  Future<void> transitionTo(GameState nextState) async {
    _currentState = nextState;
    _stateChangeController.add(nextState);

    if (nextState.phase == GamePhase.gameOver) {
      _handleGameOver(nextState);
    }
  }

  void _handleGameOver(GameState state) {
    onGameOver(
      GameResult(
        state.playerScore > state.opponentScore
            ? GameOutcome.win
            : state.playerScore < state.opponentScore
            ? GameOutcome.loss
            : GameOutcome.draw,
        points: state.playerScore,
        opponentPoints: state.opponentScore,
      ),
    );
  }

  void dispose() {
    _stateChangeController.close();
  }
}
