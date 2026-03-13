import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/ui/message_handler_registry.dart';

abstract interface class BleGameService {
  void setRegistry(MessageHandlerRegistry registry);

  Future<void> sendPlayCardAction(Card card, PlayerType player);

  Future<void> sendDrawCardAction(PlayerType player);

  Future<void> sendGameResign();
}
