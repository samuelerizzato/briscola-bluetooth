import 'dart:developer';

import 'package:briscola/ble/ble_game_central_service.dart';
import 'package:briscola/ble/messages/card_play_message.dart';
import 'package:briscola/ble/messages/draw_card_message.dart';
import 'package:briscola/game/game_result.dart';
import 'package:briscola/game/states/game_context.dart';
import 'package:briscola/game/game_client.dart';
import 'package:briscola/ui/screens/game_result_screen.dart';
import 'package:briscola/ui/widgets/game_pop_scope.dart';

import 'package:briscola/game/briscola_world.dart';
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

  late final GameClient _client;
  late final StateMachine _stateMachine;

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

    _stateMachine = StateMachine(
      GameContext(widget._leadPlayer, (GameResult result) {
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
      widget._seed,
      _stateMachine,
      _handleLocalPlayCard,
      _handleLocalDrawCard,
    );
    _client = GameClient(_stateMachine.context, world);
    widget._service.registerOpponentEventHandlers(
      _handleRemoteDraw,
      _handleRemotePlayCard,
      _handleRemoteResign,
    );
    _game = BriscolaGame(world);
  }

  void _handleLocalPlayCard(Hand hand, game.Card card) async {
    try {
      await widget._service.sendPlayCardAction(card, hand.type);
    } catch (e) {
      SnackbarManager.show("Error while sending update");
    }
  }

  void _handleLocalDrawCard(Hand hand) async {
    try {
      await widget._service.sendDrawCardAction(hand.type);
    } catch (e) {
      SnackbarManager.show("Error while sending update");
    }
  }

  void _handleRemoteDraw(DrawCardMessage message) {
    log('Received move in the CLIENT');
    Hand hand = _client.getHandByType(message.playerType);
    _client.applyDrawCard(hand);
  }

  Future<void> _handleRemotePlayCard(CardPlayMessage message) {
    log('Received message play card');
    Hand hand = _client.getHandByType(message.playerType);
    return _client.applyPlayCard(hand, message.card);
  }

  void _handleRemoteResign() {
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
