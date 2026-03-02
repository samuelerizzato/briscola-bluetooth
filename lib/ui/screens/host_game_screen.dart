import 'dart:math';
import 'dart:developer' as dev;
import 'package:briscola/game/commands/draw_card_command.dart';
import 'package:briscola/game/commands/play_card_command.dart';
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

  late final PlayCardCommand _playCardCommand;
  late final DrawCardCommand _drawCardCommand;

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
    final world = BriscolaWorld(seed, _stateMachine, _handleSetup);

    _playCardCommand = PlayCardCommand(
      gameContext.playingSurface,
      world.applyPlayCard,
    );

    _drawCardCommand = DrawCardCommand(gameContext.deck, world.applyDrawCard);

    gameContext.deck.onDrawCard = _handleLocalDrawCard;
    gameContext.playerHand.onPlayCard = _handleLocalPlayCard;

    _service = BleGamePeripheralService(widget._central, seed, leadPlayer);
    _service.registerOpponentEventHandlers(
      _handleRemoteDraw,
      _handleRemotePlayCard,
      _handleRemoteResign,
    );
    _game = BriscolaGame(world);
  }

  void _handleLocalPlayCard(game.Card card) async {
    Hand hand = _stateMachine.context.playerHand;
    _playCardCommand.execute(hand, card);
    try {
      await _service.sendPlayCardAction(card, hand.type);
    } catch (e) {
      SnackbarManager.show("Error while sending update");
    }
  }

  void _handleLocalDrawCard() async {
    _drawCardCommand.execute(_stateMachine.context.playerHand);
    try {
      await _service.sendDrawCardAction(_stateMachine.context.playerHand.type);
    } catch (e) {
      SnackbarManager.show("Error while sending update");
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
    _drawCardCommand.execute(_stateMachine.context.opponentHand);
    try {
      await _service.sendDrawCardAction(PlayerType.remote);
    } catch (e) {
      SnackbarManager.show("Error while sending update");
    }
  }

  Future<void> _handleRemotePlayCard(CardPlayMessage message) async {
    _playCardCommand.execute(_stateMachine.context.opponentHand, message.card);
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
