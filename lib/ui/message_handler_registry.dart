import 'dart:typed_data';

import 'package:briscola/ble/messages/ble_message.dart';

class MessageHandlerRegistry {
  final Map<int, Future<void> Function(Uint8List)> _handlers = {};

  void register<T extends BleMessage>(
    int messageType,
    T Function(Uint8List) parser,
    Future<void> Function(T message) action,
  ) {
    _handlers[messageType] = (bytes) async {
      final message = parser(bytes);
      return action(message);
    };
  }

  Future<void> Function(Uint8List) getHandler(int type) =>
      _handlers[type] ?? (throw RangeError('message type not found'));
}
