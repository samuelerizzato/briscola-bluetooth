import 'package:briscola/ble/ble_game_central_service.dart';
import 'package:briscola/ble/messages/card_play_message.dart';
import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/snackbar.dart';

import 'components/card.dart';

class BriscolaWorldCentral extends BriscolaWorld {
  final BleGameCentralService _bleGameCentral;

  BriscolaWorldCentral(
    super.initialSeed,
    super.gameContext,
    this._bleGameCentral,
  ) {
    _bleGameCentral.setNotificationCallbacks(
      triggerOpponentDraw,
      _handlePlayCardNotification,
    );
  }

  void _handlePlayCardNotification(CardPlayMessage notification) {
    onRemotePlayCard(notification.card);
  }

  @override
  Future<void> onLocalPlayCard(Card card) async {
    try {
      await _bleGameCentral.sendCard(card);
      super.onLocalPlayCard(card);
    } catch (e) {
      SnackbarManager.show('Error while sending card');
    }
  }

  @override
  Future<void> handlePlayerDraw() async {
    try {
      await _bleGameCentral.sendDrawCard();
      super.handlePlayerDraw();
    } catch (e) {
      SnackbarManager.show('Error while drawing card');
    }
  }
}
