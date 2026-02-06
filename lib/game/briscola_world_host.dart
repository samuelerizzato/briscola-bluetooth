import 'package:briscola/ble/ble_game_peripheral_service.dart';
import 'package:briscola/snackbar.dart';

import 'briscola_world.dart';
import 'components/card.dart';

class BriscolaWorldHost extends BriscolaWorld {
  final BleGamePeripheralService _peripheral;
  final void Function() _onSetupError;

  BriscolaWorldHost(
    super._initialSeed,
    super.context,
    this._peripheral,
    this._onSetupError,
  ) {
    _peripheral.onDrawCardWriteRequest = triggerOpponentDraw;
    _peripheral.onPlayCardWriteRequest = (request) {
      onRemotePlayCard(request.card);
    };
  }

  @override
  Future<void> setup() async {
    super.setup();
    try {
      await _peripheral.setupBleGame();
    } catch (e) {
      SnackbarManager.show('Cannot setup game');
      _onSetupError();
    }
  }

  @override
  Future<void> onLocalPlayCard(Card card) async {
    try {
      await _peripheral.notifyPlayCard(card);
      super.onLocalPlayCard(card);
    } catch (e) {
      SnackbarManager.show('Error while sending card');
    }
  }

  @override
  Future<void> handlePlayerDraw() async {
    try {
      await _peripheral.notifyDrawCard();
      super.handlePlayerDraw();
    } catch (e) {
      SnackbarManager.show('Error while drawing card');
    }
  }
}
