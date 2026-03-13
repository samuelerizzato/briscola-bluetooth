import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:developer' as dev;
import 'package:briscola/ble/messages/start_game_message.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import 'package:briscola/ble/messages/resign_message.dart';
import 'package:briscola/ble/messages/card_play_message.dart';
import 'package:briscola/ble/messages/draw_card_message.dart';
import 'package:briscola/ble/ble_game_peripheral_service.dart';

import 'package:briscola/game/states/game_state.dart';
import 'package:briscola/game/turn_system.dart';
import 'package:briscola/game/suit.dart';
import 'package:briscola/game/game_result.dart';
import 'package:briscola/game/game_actions.dart';
import 'package:briscola/game/states/game_context.dart';
import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/components/hand.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/states/state_machine.dart';
import 'package:briscola/game/briscola_game.dart';
import 'package:briscola/game/components/card.dart' as game;

import 'package:briscola/ui/message_handler_registry.dart';
import 'package:briscola/ui/screens/game_result_screen.dart';
import 'package:briscola/ui/widgets/game_pop_scope.dart';

import 'package:briscola/snackbar.dart';

class HostGameScreen extends StatefulWidget {
  final Central _central;

  const HostGameScreen(this._central, {super.key});

  @override
  State<StatefulWidget> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends State<HostGameScreen> {
  late final BriscolaGame _game;
  late final StateMachine _stateMachine;
  late final BleGamePeripheralService _service;
  late final TurnSystem _turnSystem;
  late final GameActions _gameActions;

  final List<StreamSubscription?> _gameStateChangedSubscriptions = [];

  final Queue<Future<void> Function()> _eventsQueue = Queue();
  bool _isEventExecuting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game')),
      body: GamePopScope(
        _stopGame,
        child: Stack(
          fit: StackFit.expand,
          children: [GameWidget(game: _game)],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    final gameContext = GameContext();

    int seed = Random().nextInt(256);
    PlayerType leadPlayer = Random(seed).nextBool()
        ? PlayerType.local
        : PlayerType.remote;

    _initStateMachine(gameContext, leadPlayer);

    gameContext.deck.onDrawCard = () {
      _handleDraw(gameContext.playerHand);
    };
    gameContext.playerHand.onPlayCard = (card) {
      _handlePlayCard(gameContext.playerHand, card);
    };

    _service = BleGamePeripheralService(widget._central, seed, leadPlayer);
    _service.setRegistry(_createRegistry(gameContext));

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

    _game = BriscolaGame(
      BriscolaWorld(seed, _stateMachine, gameContext, _handleSetup),
    );
  }

  Future<bool> _stopGame() async {
    try {
      await _service.sendGameResign();
      return true;
    } catch (e) {
      dev.log(e.toString());
      SnackbarManager.show('Error, unable to leave the game');
      return false;
    }
  }

  void _initStateMachine(GameContext gameContext, PlayerType leadPlayer) {
    Hand current;
    Hand next;
    if (leadPlayer == PlayerType.local) {
      current = gameContext.playerHand;
      next = gameContext.opponentHand;
    } else {
      current = gameContext.opponentHand;
      next = gameContext.playerHand;
    }

    _stateMachine = StateMachine(
      GameState(current, next, GamePhase.initial, 0, 0),
      (GameResult result) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              builder: (context) => GameResultScreen(result: result),
            ),
          );
        }
      },
    );

    List<void Function(GameState)> gameStateListeners = [
      gameContext.deck.onGameStateChanged,
      gameContext.playerHand.onGameStateChanged,
      gameContext.playerTricksPile.onGameStateChanged,
      gameContext.opponentTricksPile.onGameStateChanged,
      _sendGameStateUpdate,
    ];

    _gameStateChangedSubscriptions.addAll(
      gameStateListeners.map(
        (listener) => _stateMachine.stateChanged.listen(listener),
      ),
    );
  }

  MessageHandlerRegistry _createRegistry(GameContext gameContext) =>
      MessageHandlerRegistry()
        ..register<StartGameMessage>(
          StartGameMessage.eventType,
          StartGameMessage.fromBytes,
          _startGame,
        )
        ..register<DrawCardMessage>(
          DrawCardMessage.eventType,
          DrawCardMessage.fromBytes,
          (message) async => _handleDraw(gameContext.opponentHand),
        )
        ..register<CardPlayMessage>(
          CardPlayMessage.eventType,
          CardPlayMessage.fromBytes,
          (message) async =>
              _handlePlayCard(gameContext.opponentHand, message.card),
        )
        ..register<ResignMessage>(
          ResignMessage.eventType,
          ResignMessage.fromBytes,
          _handleRemoteResign,
        );

  void _handleSetup() async {
    try {
      await _service.setupBleGame();
    } catch (e) {
      SnackbarManager.show("Cannot setup game");
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _startGame(StartGameMessage message) async {
    _stateMachine.initialize(
      _stateMachine.currentState.copyWith(phase: GamePhase.play),
    );
  }

  void _addAndExecute(Future<void> Function() action) async {
    _eventsQueue.add(action);
    if (_isEventExecuting) return;

    _isEventExecuting = true;

    while (_eventsQueue.isNotEmpty) {
      final event = _eventsQueue.removeFirst();
      await event();
    }

    _isEventExecuting = false;
  }

  Future<void> _sendGameStateUpdate(GameState state) async {
    _addAndExecute(() async {
      try {
        await _service.sendGameStateUpdate(state);
        if (state.phase == GamePhase.trickEnd) {
          _handleTrickEnd(state.currentHand.type);
        }
      } catch (e) {
        SnackbarManager.show("Error while sending game state update");
      }
    });
  }

  void _handlePlayCard(Hand hand, game.Card card) async {
    if (!_turnSystem.canPlay(hand.type)) return;

    _addAndExecute(() async {
      _gameActions.playCard(hand, card);
      try {
        await _service.sendPlayCardAction(card, hand.type);
      } catch (e) {
        SnackbarManager.show("Error while sending card play");
      }
    });
  }

  void _handleTrickEnd(PlayerType winner) async {
    _addAndExecute(() async {

      try {
        await Future.wait([
          _gameActions.animateTrickEnd(winner),
          _service.sendTrickEndEvent(winner),
        ]);
        _turnSystem.decideNextTurn();
      } catch (e) {
        SnackbarManager.show("Error while sending state update");
      }
    });
  }

  void _handleDraw(Hand hand) async {
    if (!_turnSystem.canDraw(hand.type)) return;

    _addAndExecute(() async {
      _gameActions.drawCard(hand);
      try {
        await _service.sendDrawCardAction(hand.type);
      } catch (e) {
        SnackbarManager.show("Error while sending draw card");
      }
    });
  }

  Future<void> _handleRemoteResign(ResignMessage message) async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            GameResultScreen(result: GameResult(GameOutcome.opponentResigned)),
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
    _service.dispose();
    super.dispose();
  }
}
