import 'dart:math';
import 'dart:developer' as dev;
import 'package:briscola/game/commands/command_invoker.dart';
import 'package:briscola/game/commands/move_command.dart';
import 'package:briscola/game/components/deck_pile.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import 'package:briscola/ble/messages/card_play_message.dart';
import 'package:briscola/ble/messages/draw_card_message.dart';
import 'package:briscola/game/game_result.dart';
import 'package:briscola/game/states/game_context.dart';
import 'package:briscola/ui/screens/game_result_screen.dart';
import 'package:briscola/ui/widgets/game_pop_scope.dart';

import 'package:briscola/ble/ble_game_peripheral_service.dart';
import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/components/hand.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/states/state_machine.dart';
import 'package:briscola/game/briscola_game.dart';
import 'package:briscola/game/components/card.dart' as game;
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
    int seed = Random().nextInt(256);
    PlayerType leadPlayer = Random(seed).nextBool()
        ? PlayerType.local
        : PlayerType.remote;

    final gameContext = GameContext(leadPlayer, (GameResult result) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (context) => GameResultScreen(result: result),
          ),
        );
      }
    });

    _stateMachine = StateMachine(gameContext);

    gameContext.deck.onDrawCard = _handleLocalDrawCard;
    gameContext.playerHand.onPlayCard = _handleLocalPlayCard;

    _service = BleGamePeripheralService(widget._central, seed, leadPlayer);
    _service.registerOpponentEventHandlers(
      _handleRemoteDraw,
      _handleRemotePlayCard,
      _handleRemoteResign,
    );
    _game = BriscolaGame(BriscolaWorld(seed, _stateMachine, _handleSetup));
  }

  void _handleLocalPlayCard(game.Card card) async {
    Hand hand = _stateMachine.context.playerHand;
    _processPlayCard(hand, card);

    try {
      await _service.sendPlayCardAction(card, hand.type);
    } catch (e) {
      SnackbarManager.show("Error while sending card play");
    }
  }

  void _processPlayCard(Hand hand, game.Card card) {
    PlayingSurface surface = _stateMachine.context.playingSurface;
    if (hand.isEnabled && surface.canAcquireCard(hand.type)) {
      CommandInvoker.execute(MoveCommand(hand, surface, card));
      _stateMachine.transitionTo(_stateMachine.turnEndState);
    }
  }

  void _handleLocalDrawCard() async {
    Hand hand = _stateMachine.context.playerHand;
    _processDrawCard(hand);

    try {
      await _service.sendDrawCardAction(hand.type);
    } catch (e) {
      SnackbarManager.show("Error while sending draw card");
    }
  }

  void _processDrawCard(Hand hand) {
    DeckPile deck = _stateMachine.context.deck;
    if (!deck.isEmpty) {
      CommandInvoker.execute(MoveCommand(deck, hand, deck.topCard));
      _stateMachine.transitionTo(_stateMachine.drawEndState);
    }
  }

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

  void _handleRemoteDraw(DrawCardMessage message) async {
    _processDrawCard(_stateMachine.context.opponentHand);
    try {
      await _service.sendDrawCardAction(PlayerType.remote);
    } catch (e) {
      SnackbarManager.show("Error while sending update");
    }
  }

  Future<void> _handleRemotePlayCard(CardPlayMessage message) async {
    _processPlayCard(_stateMachine.context.opponentHand, message.card);
    try {
      await _service.sendPlayCardAction(message.card, PlayerType.remote);
    } catch (e) {
      SnackbarManager.show("Error while sending update");
    }
  }

  void _handleRemoteResign() {
    dev.log('push with replacement');
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
      await _service.sendGameResign();
      return true;
    } catch (e) {
      SnackbarManager.show('Error, unable to leave the game');
      return false;
    }
  }

  @override
  void dispose() {
    _stateMachine.dispose();
    _service.dispose();
    super.dispose();
  }
}
