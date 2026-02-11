import 'package:briscola/ble/messages/card_play_message.dart';
import 'package:briscola/game/components/card.dart';

abstract interface class BleGameService {
  Future<void> sendPlayCardAction(Card card);

  Future<void> sendDrawCardAction();

  void registerOpponentEventHandlers(
    void Function() onDrawCard,
    void Function(CardPlayMessage) onPlayCard,
  );
}
