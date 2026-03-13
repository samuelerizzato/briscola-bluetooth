import 'dart:async';
import 'dart:math';
import 'package:briscola/game/game_actions.dart';
import 'package:briscola/game/suit.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import 'package:briscola/game/briscola_game.dart';
import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/game_result.dart';
import 'package:briscola/game/states/game_context.dart';
import 'package:briscola/game/states/game_state.dart';
import 'package:briscola/game/states/state_machine.dart';
import 'package:briscola/game/turn_system.dart';
import 'package:briscola/ui/screens/game_result_screen.dart';
import 'package:briscola/ui/widgets/game_pop_scope.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<StatefulWidget> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final BriscolaGame _game;
  late final StateMachine _stateMachine;
  late final TurnSystem _turnSystem;
  late final GameActions _gameActions;

  final List<StreamSubscription?> _gameStateChangedSubscriptions = [];

  @override
  void initState() {
    super.initState();

    final gameContext = GameContext();

    _initStateMachine(gameContext);

    gameContext.deck.onDrawCard = () {
      if (_turnSystem.canDraw(gameContext.playerHand.type)) {
        _gameActions.drawCard(gameContext.playerHand);
      }
    };

    gameContext.playerHand.onPlayCard = (card) {
      if (_turnSystem.canPlay(gameContext.playerHand.type)) {
        _gameActions.playCard(gameContext.playerHand, card);
      }
    };

    int seed = Random().nextInt(256);
    gameContext.briscolaSuit =
        SuitType.values[Random(seed).nextInt(SuitType.values.length)];

    _turnSystem = TurnSystem(
      _stateMachine,
      gameContext.playingSurface,
      gameContext.deck,
      gameContext.briscolaSuit,
    );

    _gameActions = GameActions(
      gameContext.playingSurface,
      gameContext.deck,
      gameContext.playerTricksPile,
      gameContext.opponentTricksPile,
    );

    _game = BriscolaGame(BriscolaWorld(seed, _stateMachine, gameContext));
    _stateMachine.initialize(
      _stateMachine.currentState.copyWith(phase: GamePhase.play),
    );
  }

  void _initStateMachine(GameContext gameContext) {
    _stateMachine = StateMachine(
      GameState(
        gameContext.playerHand,
        gameContext.opponentHand,
        GamePhase.initial,
        0,
        0,
      ),
      (GameResult result) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (context) => GameResultScreen(result: result),
          ),
        );
      },
    );

    List<void Function(GameState)> gameStateListeners = [
      gameContext.deck.onGameStateChanged,
      gameContext.playerHand.onGameStateChanged,
      gameContext.playerTricksPile.onGameStateChanged,
      gameContext.opponentTricksPile.onGameStateChanged,
      _handleTrickEnd,
      (state) {
        _handleOpponentActions(gameContext, state);
      },
    ];

    _gameStateChangedSubscriptions.addAll(
      gameStateListeners.map(
        (listener) => _stateMachine.stateChanged.listen(listener),
      ),
    );
  }

  void _handleTrickEnd(GameState state) async {
    if (state.phase == GamePhase.trickEnd) {
      await _gameActions.animateTrickEnd(state.currentHand.type);
      _turnSystem.decideNextTurn();
    }
  }

  void _handleOpponentActions(GameContext gameContext, GameState state) {
    if (state.currentHand.type != PlayerType.remote) {
      return;
    }

    if (state.phase == GamePhase.play) {
      final hand = gameContext.opponentHand;
      _gameActions.playCard(hand, hand.cards.last);
    } else if (state.phase == GamePhase.draw) {
      _gameActions.drawCard(gameContext.opponentHand);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game')),
      body: GamePopScope(
        () async => true,
        child: Stack(
          fit: StackFit.expand,
          children: [GameWidget(game: _game)],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _gameStateChangedSubscriptions) {
      subscription?.cancel();
    }
    _turnSystem.dispose();
    _stateMachine.dispose();
    super.dispose();
  }
}
