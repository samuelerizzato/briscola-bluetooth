import 'dart:math';
import 'dart:developer' as dev;
import 'package:briscola/ble/messages/card_play_message.dart';
import 'package:briscola/ble/messages/draw_card_message.dart';
import 'package:briscola/game/game_result.dart';
import 'package:briscola/game/states/game_context.dart';
import 'package:briscola/ui/screens/game_result_screen.dart';
import 'package:briscola/ui/widgets/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import 'package:briscola/ble/ble_game_peripheral_service.dart';
import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/components/hand.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/states/state_machine.dart';
import 'package:briscola/game/game_server.dart';
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

  late final BleGamePeripheralService _service;
  late final GameServer _server;
  late final StateMachine _stateMachine;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game')),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) return;

          final bool shouldPop =
              await Dialogs.showBackDialog(context, _stopGame) ?? false;
          if (context.mounted && shouldPop) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const GameResultScreen(
                  result: GameResult(GameOutcome.resigned),
                ),
              ),
            );
          }
        },
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

    _stateMachine = StateMachine(
      GameContext(leadPlayer, (GameResult result) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              builder: (context) => GameResultScreen(result: result),
            ),
          );
        }
      }),
    );

    final world = BriscolaWorld(
      seed,
      _stateMachine,
      _handleLocalPlayCard,
      _handleLocalDrawCard,
      _handleSetup,
    );
    _server = GameServer(world, _stateMachine.context);
    _service = BleGamePeripheralService(widget._central, seed, leadPlayer);
    _service.registerOpponentEventHandlers(
      _handleRemoteDraw,
      _handleRemotePlayCard,
      _handleRemoteResign,
    );
    _game = BriscolaGame(world);
  }

  void _handleLocalPlayCard(Hand hand, game.Card card) async {
    if (!_server.applyPlayCard(hand, card)) return;

    try {
      await _service.sendPlayCardAction(card, hand.type);
    } catch (e) {
      SnackbarManager.show("Error while sending update");
    }
  }

  void _handleLocalDrawCard(Hand hand) async {
    if (!_server.applyDrawCard(hand)) {
      return;
    }
    try {
      await _service.sendDrawCardAction(hand.type);
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
    if (!_server.applyDrawCard(_server.opponentHand)) {
      return;
    }
    try {
      await _service.sendDrawCardAction(PlayerType.remote);
    } catch (e) {
      SnackbarManager.show("Error while sending update");
    }
  }

  Future<void> _handleRemotePlayCard(CardPlayMessage message) async {
    if (!_server.applyPlayCard(_server.opponentHand, message.card)) {
      return;
    }
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

  Future<void> _stopGame() async {
    try {
      await _service.sendGameResign();
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      SnackbarManager.show('Error, unable to leave the game');
    }
  }

  @override
  void dispose() {
    _stateMachine.dispose();
    _service.dispose();
    super.dispose();
  }
}
