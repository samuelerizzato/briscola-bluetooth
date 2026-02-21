import 'dart:async';
import 'dart:math';

import 'package:briscola/game/briscola_game.dart';
import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/commands/draw_card_command.dart';
import 'package:briscola/game/commands/play_card_command.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/game_result.dart';
import 'package:briscola/game/states/game_context.dart';
import 'package:briscola/game/states/opponent_draw_state.dart';
import 'package:briscola/game/states/opponent_turn_state.dart';
import 'package:briscola/game/states/state_machine.dart';
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
  late final BriscolaWorld _world;
  late final StateMachine _stateMachine;

  late final PlayCardCommand _playCardCommand;
  late final DrawCardCommand _drawCardCommand;

  StreamSubscription? _gameStateChangedSubscription;

  @override
  void initState() {
    super.initState();

    final gameContext = GameContext(PlayerType.local, (GameResult result) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (context) => GameResultScreen(result: result),
        ),
      );
    });

    _stateMachine = StateMachine(gameContext);

    _world = BriscolaWorld(
      Random().nextInt(256),
      _stateMachine,
      _playCardCommand.execute,
      _drawCardCommand.execute,
    );

    _playCardCommand = PlayCardCommand(
      gameContext.playingSurface,
      _world.applyPlayCard,
    );

    _drawCardCommand = DrawCardCommand(gameContext.deck, _world.applyDrawCard);

    _gameStateChangedSubscription = _stateMachine.stateChanged.listen((state) {
      if (state is OpponentTurnState) {
        final hand = _stateMachine.context.opponentHand;
        _playCardCommand.execute(hand, hand.cards.last);
      } else if (state is OpponentDrawState) {
        _drawCardCommand.execute(_stateMachine.context.opponentHand);
      }
    });

    _game = BriscolaGame(_world);
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

  @override
  void dispose() {
    _gameStateChangedSubscription?.cancel();
    _stateMachine.dispose();
    super.dispose();
  }
}
