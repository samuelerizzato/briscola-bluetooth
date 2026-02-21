import 'dart:async';
import 'dart:math';

import 'package:briscola/game/briscola_game.dart';
import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/game_result.dart';
import 'package:briscola/game/states/game_context.dart';
import 'package:briscola/game/states/opponent_draw_state.dart';
import 'package:briscola/game/states/opponent_turn_state.dart';
import 'package:briscola/game/states/state_machine.dart';
import 'package:briscola/game/game_server.dart';
import 'package:briscola/snackbar.dart';
import 'package:briscola/ui/screens/game_result_screen.dart';
import 'package:briscola/ui/widgets/game_pop_scope.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<StatefulWidget> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final BriscolaGame _game;
  late final GameServer _server;
  late final StateMachine _stateMachine;

  StreamSubscription? _gameStateChangedSubscription;

  @override
  void initState() {
    super.initState();

    _stateMachine = StateMachine(
      GameContext(PlayerType.local, (GameResult result) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (context) => GameResultScreen(result: result),
          ),
        );
      }),
    );

    final world = BriscolaWorld(
      Random().nextInt(256),
      _stateMachine,
      (hand, card) {
        _server.applyPlayCard(hand, card);
      },
      (hand) {
        _server.applyDrawCard(hand);
      },
    );

    _server = GameServer(world, _stateMachine.context);
    _gameStateChangedSubscription = _stateMachine.stateChanged.listen((state) {
      if (state is OpponentTurnState) {
        final hand = _server.opponentHand;
        if (!_server.applyPlayCard(hand, hand.cards.last)) {
          SnackbarManager.show('Opponent can\'t play the card');
        }
      } else if (state is OpponentDrawState) {
        if (!_server.applyDrawCard(_server.opponentHand)) {
          SnackbarManager.show('Opponent can\'t draw a card');
        }
      }
    });

    _game = BriscolaGame(world);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game'),
        backgroundColor: _game.backgroundColor(),
        foregroundColor: Colors.white,
        elevation: 0.0,
      ),
      body: GamePopScope(
        () async => true,
        child: Stack(
          fit: StackFit.expand,
          children: [GameWidget(game: _game)],
        ),
      ),
    );
  }

  void _stopGame() {
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _gameStateChangedSubscription?.cancel();
    _stateMachine.dispose();
    super.dispose();
  }
}
