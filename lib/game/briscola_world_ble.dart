import 'package:briscola/ble/ble_game_service.dart';
import 'package:briscola/snackbar.dart';

import 'briscola_world.dart';
import 'components/card.dart';

class BriscolaWorldBle extends BriscolaWorld {
  final BleGameService _bleService;
  final void Function()? _onSetup;

  BriscolaWorldBle(
    super._initialSeed,
    super.context,
    this._bleService,
    this._onSetup,
  ) {
    _bleService.registerOpponentEventHandlers(triggerOpponentDraw, (request) {
      onRemotePlayCard(request.card);
    });
  }

  @override
  Future<void> setup() async {
    super.setup();
    _onSetup?.call();
  }

  @override
  Future<void> onLocalPlayCard(Card card) async {
    try {
      await _bleService.sendPlayCardAction(card);
      super.onLocalPlayCard(card);
    } catch (e) {
      SnackbarManager.show('Error while sending card');
    }
  }

  @override
  Future<void> handlePlayerDraw() async {
    try {
      await _bleService.sendDrawCardAction();
      super.handlePlayerDraw();
    } catch (e) {
      SnackbarManager.show('Error while drawing card');
    }
  }
}
