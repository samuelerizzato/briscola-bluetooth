import 'dart:async';

import 'package:briscola/game/states/decide_state.dart';
import 'package:briscola/game/states/game_context.dart';
import 'package:briscola/game/states/game_over_state.dart';
import 'package:briscola/game/states/game_state.dart';
import 'package:briscola/game/states/player_turn_state.dart';
import 'package:briscola/game/states/opponent_draw_state.dart';
import 'package:briscola/game/states/opponent_turn_state.dart';
import 'package:briscola/game/states/player_draw_state.dart';
import 'package:briscola/game/states/turn_end_state.dart';

class StateMachine {
  GameState? _currentState;

  final GameContext _context;

  final PlayerDrawState playerDrawState;
  final OpponentDrawState opponentDrawState;
  final PlayerTurnState playerTurnState;
  final OpponentTurnState opponentTurnState;
  final TurnEndState turnEndState;
  final DecideState decideState;
  final GameOverState gameOverState;

  final StreamController<GameState> _stateChangeController =
      StreamController<GameState>.broadcast();

  Stream<GameState> get stateChanged => _stateChangeController.stream;

  GameState? get currentState => _currentState;

  GameContext get context => _context;

  StateMachine(this._context)
    : playerDrawState = PlayerDrawState(),
      opponentDrawState = OpponentDrawState(),
      playerTurnState = PlayerTurnState(),
      opponentTurnState = OpponentTurnState(),
      turnEndState = TurnEndState(),
      decideState = DecideState(),
      gameOverState = GameOverState();

  Future<void> initialize(GameState state) async {
    _currentState = state;
    await state.enter(this);

    _stateChangeController.add(state);
  }

  Future<void> transitionTo(GameState nextState) async {
    await _currentState?.exit(this);
    _currentState = nextState;
    await nextState.enter(this);

    _stateChangeController.add(nextState);
  }

  void dispose() {
    _stateChangeController.close();
  }
}
