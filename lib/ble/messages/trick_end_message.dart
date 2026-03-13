import 'dart:typed_data';

import 'package:briscola/ble/conversions.dart';
import 'package:briscola/ble/messages/ble_message.dart';
import 'package:briscola/game/components/playing_surface.dart';

class TrickEndMessage implements BleMessage {
  static const int eventType = 2;

  final PlayerType currentPlayer;

  TrickEndMessage(this.currentPlayer);

  @override
  Uint8List toBytes() {
    final builder = BytesBuilder();
    builder.addByte(eventType);
    builder.add(
      Conversions.boolToUint8List(currentPlayer == PlayerType.remote),
    );
    return builder.toBytes();
  }

  factory TrickEndMessage.fromBytes(Uint8List bytes) => TrickEndMessage(
    Conversions.byteToBool(bytes[1])
        ? PlayerType.local
        : PlayerType.remote,
  );
}
