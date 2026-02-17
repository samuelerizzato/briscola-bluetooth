import 'package:briscola/ble/messages/card_play_message.dart';
import 'package:briscola/ble/messages/draw_card_message.dart';
import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/playing_surface.dart';

abstract interface class BleGameService {
  void registerOpponentEventHandlers(
    void Function(DrawCardMessage message) onDrawCard,
    Future<void> Function(CardPlayMessage message) onPlayCard,
    void Function() onResign,
  );

  Future<void> sendPlayCardAction(Card card, PlayerType player);

  Future<void> sendDrawCardAction(PlayerType player);

  Future<void> sendGameResign();
}
