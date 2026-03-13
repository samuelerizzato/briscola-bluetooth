import 'dart:typed_data';

import 'package:briscola/ble/messages/ble_message.dart';

class StartGameMessage implements BleMessage {
  static const int eventType = 5;

  StartGameMessage();

  @override
  Uint8List toBytes() => Uint8List(1)..[0] = eventType;

  factory StartGameMessage.fromBytes(Uint8List bytes) => StartGameMessage();
}