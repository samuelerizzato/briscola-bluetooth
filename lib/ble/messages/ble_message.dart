import 'dart:typed_data';

abstract class BleMessage {
  Uint8List toBytes();
}
