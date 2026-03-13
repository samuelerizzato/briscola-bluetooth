import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import 'package:briscola/ble/messages/resign_message.dart';
import 'package:briscola/ble/messages/game_state_message.dart';
import 'package:briscola/ble/messages/trick_end_message.dart';
import 'package:briscola/ble/ble_game_central_service.dart';
import 'package:briscola/ble/messages/card_play_message.dart';
import 'package:briscola/ble/messages/draw_card_message.dart';

import 'package:briscola/ui/message_handler_registry.dart';
import 'package:briscola/ui/screens/game_result_screen.dart';
import 'package:briscola/ui/widgets/game_pop_scope.dart';

import 'package:briscola/game/suit.dart';
import 'package:briscola/game/states/game_state.dart';
import 'package:briscola/game/game_actions.dart';
import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/game_result.dart';
import 'package:briscola/game/states/game_context.dart';
import 'package:briscola/game/components/hand.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/states/state_machine.dart';
import 'package:briscola/game/briscola_game.dart';
import 'package:briscola/game/components/card.dart' as game;
import 'package:briscola/snackbar.dart';

class ClientGameScreen extends StatefulWidget {
  final BleGameCentralService _service;
  final int _seed;
  final PlayerType _leadPlayer;

  const ClientGameScreen(
    this._seed,
    this._leadPlayer,
    this._service, {
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _ClientGameScreenState();
}

class _ClientGameScreenState extends State<ClientGameScreen> {
  late final BriscolaGame _game;
  late final StateMachine _stateMachine;
  late final GameActions _gameActions;

  final List<StreamSubscription?> _gameStateChangedSubscriptions = [];

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
    _initStateMachine(gameContext);

    gameContext.playerHand.onPlayCard = _handleLocalPlayCard;
    gameContext.deck.onDrawCard = _handleLocalDrawCard;
    gameContext.briscolaSuit =
        SuitType.values[Random(widget._seed).nextInt(SuitType.values.length)];

    _gameActions = GameActions(
      gameContext.playingSurface,
      gameContext.deck,
      gameContext.playerTricksPile,
      gameContext.opponentTricksPile,
    );

    _game = BriscolaGame(
      BriscolaWorld(widget._seed, _stateMachine, gameContext),
    );
    _setupService(gameContext);
  }

  void _initStateMachine(GameContext gameContext) {
    Hand current;
    Hand next;

    if (widget._leadPlayer == PlayerType.local) {
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
    ];

    _gameStateChangedSubscriptions.addAll(
      gameStateListeners.map(
        (listener) => _stateMachine.stateChanged.listen(listener),
      ),
    );

    _stateMachine.initialize(_stateMachine.currentState);
  }

  void _setupService(GameContext gameContext) async {
    widget._service.setRegistry(_createRegistry(gameContext));

    try {
      await widget._service.subscribeToGameStateCharacteristic();
    } catch (e) {
      SnackbarManager.show('Cannot connect to game state characteristic');
      // disconnect
      return;
    }

    try {
      await widget._service.sendStartGameRequest();
    } catch (e) {
      SnackbarManager.show('Cannot connect to game state characteristic');
      // disconnect
    }
  }

  MessageHandlerRegistry _createRegistry(GameContext gameContext) =>
      MessageHandlerRegistry()
        ..register<DrawCardMessage>(
          DrawCardMessage.eventType,
          DrawCardMessage.fromBytes,
          (message) => _handleRemoteDraw(gameContext, message),
        )
        ..register<CardPlayMessage>(
          CardPlayMessage.eventType,
          CardPlayMessage.fromBytes,
          (message) => _handleRemotePlayCard(gameContext, message),
        )
        ..register<TrickEndMessage>(
          TrickEndMessage.eventType,
          TrickEndMessage.fromBytes,
          _handleTrickEnd,
        )
        ..register<GameStateMessage>(
          GameStateMessage.eventType,
          GameStateMessage.fromBytes,
          (message) => _handleGameStateUpdate(gameContext, message),
        )
        ..register<ResignMessage>(
          ResignMessage.eventType,
          ResignMessage.fromBytes,
          _handleRemoteResign,
        );

  Hand _getHandByType(GameContext context, PlayerType type) =>
      type == PlayerType.local ? context.playerHand : context.opponentHand;

  void _handleLocalPlayCard(game.Card card) async {
    try {
      await widget._service.sendPlayCardAction(card, PlayerType.local);
    } catch (e) {
      SnackbarManager.show("Error while sending update");
    }
  }

  void _handleLocalDrawCard() async {
    try {
      await widget._service.sendDrawCardAction(PlayerType.local);
    } catch (e) {
      SnackbarManager.show("Error while sending update");
    }
  }

  Future<void> _handleRemoteDraw(
    GameContext gameContext,
    DrawCardMessage message,
  ) async {
    Hand hand = _getHandByType(gameContext, message.playerType);
    _gameActions.drawCard(hand);
  }

  Future<void> _handleRemotePlayCard(
    GameContext gameContext,
    CardPlayMessage message,
  ) async {
    dev.log('Received message play card');
    Hand hand = _getHandByType(gameContext, message.playerType);
    _gameActions.playCard(hand, message.card);
  }

  Future<void> _handleTrickEnd(TrickEndMessage message) async {
    await _gameActions.animateTrickEnd(message.currentPlayer);
  }

  Future<void> _handleGameStateUpdate(
    GameContext gameContext,
    GameStateMessage message,
  ) async {
    Hand currentHand = _getHandByType(gameContext, message.currentPlayer);
    Hand nextHand = _getHandByType(gameContext, message.nextPlayer);

    _stateMachine.transitionTo(
      GameState(
        currentHand,
        nextHand,
        message.phase,
        message.playerScore,
        message.opponentScore,
      ),
    );
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

  Future<bool> _stopGame() async {
    try {
      await widget._service.sendGameResign();
      return true;
    } catch (e) {
      SnackbarManager.show('Error, unable to leave the game');
      return false;
    }
  }

  @override
  void dispose() {
    _stateMachine.dispose();
    widget._service.dispose();
    super.dispose();
  }
}
