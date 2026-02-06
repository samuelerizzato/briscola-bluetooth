import 'dart:typed_data';

import 'package:briscola/ble/conversions.dart';
import 'package:briscola/game/components/playing_surface.dart';

import 'ble_message.dart';

class GameSetupMessage implements BleMessage {
  final int seed;
  final PlayerType leadPlayer;

  static const int seedIndex = 0;
  static const int leadPlayerIndex = 1;

  GameSetupMessage(this.seed, this.leadPlayer);

  @override
  Uint8List toBytes() {
    final builder = BytesBuilder();
    builder.add(Conversions.intToUint8List(seed));
    builder.add(Conversions.boolToUint8List(leadPlayer == PlayerType.remote));
    return builder.toBytes();
  }

  factory GameSetupMessage.fromBytes(Uint8List bytes) => GameSetupMessage(
    bytes[seedIndex],
    Conversions.byteToBool(bytes[leadPlayerIndex])
        ? PlayerType.local
        : PlayerType.remote,
  );
}
