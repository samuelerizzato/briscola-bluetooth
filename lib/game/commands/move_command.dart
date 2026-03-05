import 'package:briscola/game/card_holder.dart';
import 'package:briscola/game/components/card.dart';

class MoveCommand {
  final CardHolder _sender;
  final CardHolder _receiver;
  final Card _card;

  MoveCommand(this._sender, this._receiver, this._card);

  void execute() {
    _receiver.acquireCard(_sender.removeCard(_card));
  }
}
