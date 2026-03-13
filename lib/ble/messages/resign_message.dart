import 'dart:typed_data';

import 'package:briscola/ble/messages/ble_message.dart';

class ResignMessage implements BleMessage {
  static const int eventType = 4;

  ResignMessage();

  @override
  Uint8List toBytes() => Uint8List(1)..[0] = eventType;

  factory ResignMessage.fromBytes(Uint8List bytes) => ResignMessage();
}