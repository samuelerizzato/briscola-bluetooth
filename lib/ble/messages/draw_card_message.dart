import 'dart:typed_data';

import 'package:briscola/ble/conversions.dart';
import 'package:briscola/ble/messages/ble_message.dart';
import 'package:briscola/game/components/playing_surface.dart';

class DrawCardMessage implements BleMessage {
  final PlayerType playerType;

  DrawCardMessage(this.playerType);

  @override
  Uint8List toBytes() =>
      Conversions.boolToUint8List(playerType == PlayerType.remote);

  factory DrawCardMessage.fromBytes(Uint8List bytes) => DrawCardMessage(
    Conversions.byteToBool(bytes[0]) ? PlayerType.local : PlayerType.remote,
  );
}
