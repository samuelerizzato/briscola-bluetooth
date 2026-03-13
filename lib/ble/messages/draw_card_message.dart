import 'dart:typed_data';

import 'package:briscola/ble/conversions.dart';
import 'package:briscola/ble/messages/ble_message.dart';
import 'package:briscola/game/components/playing_surface.dart';

class DrawCardMessage implements BleMessage {
  final PlayerType playerType;

  static const int eventType = 0;

  DrawCardMessage(this.playerType);

  @override
  Uint8List toBytes() {
    final builder = BytesBuilder();
    builder.addByte(eventType);
    builder.add(Conversions.boolToUint8List(playerType == PlayerType.remote));
    return builder.toBytes();
  }

  factory DrawCardMessage.fromBytes(Uint8List bytes) => DrawCardMessage(
    Conversions.byteToBool(bytes[1]) ? PlayerType.local : PlayerType.remote,
  );
}
