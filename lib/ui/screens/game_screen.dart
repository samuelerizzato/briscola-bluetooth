import 'dart:async';
import 'dart:math';

import 'package:briscola/game/briscola_game.dart';
import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/commands/command_invoker.dart';
import 'package:briscola/game/commands/move_command.dart';
import 'package:briscola/game/components/card.dart' as game;
import 'package:briscola/game/components/deck_pile.dart';
import 'package:briscola/game/components/hand.dart';
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
  late final StateMachine _stateMachine;

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

    gameContext.deck.onDrawCard = () {
      _processDrawCard(gameContext.playerHand);
    };

    gameContext.playerHand.onPlayCard = (card) {
      _processPlayCard(gameContext.playerHand, card);
    };

    _gameStateChangedSubscription = _stateMachine.stateChanged.listen((state) {
      if (state is OpponentTurnState) {
        final hand = _stateMachine.context.opponentHand;
        _processPlayCard(hand, hand.cards.last);
      } else if (state is OpponentDrawState) {
        _processDrawCard(_stateMachine.context.opponentHand);
      }
    });

    _game = BriscolaGame(BriscolaWorld(Random().nextInt(256), _stateMachine));
  }

  void _processPlayCard(Hand hand, game.Card card) {
    PlayingSurface surface = _stateMachine.context.playingSurface;
    if (hand.isEnabled && surface.canAcquireCard(hand.type)) {
      CommandInvoker.execute(MoveCommand(hand, surface, card));
      _stateMachine.transitionTo(_stateMachine.turnEndState);
    }
  }

  void _processDrawCard(Hand hand) {
    DeckPile deck = _stateMachine.context.deck;
    if (!deck.isEmpty) {
      CommandInvoker.execute(MoveCommand(deck, hand, deck.topCard));
      _stateMachine.transitionTo(_stateMachine.drawEndState);
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
    _gameStateChangedSubscription?.cancel();
    _stateMachine.dispose();
    super.dispose();
  }
}
