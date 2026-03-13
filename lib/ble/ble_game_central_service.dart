import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:typed_data';

import 'package:briscola/ble/ble_game_service.dart';
import 'package:briscola/ble/conversions.dart';
import 'package:briscola/ble/messages/ble_message.dart';
import 'package:briscola/ble/messages/card_play_message.dart';
import 'package:briscola/ble/messages/draw_card_message.dart';
import 'package:briscola/ble/messages/game_setup_message.dart';
import 'package:briscola/ble/messages/resign_message.dart';
import 'package:briscola/ble/messages/start_game_message.dart';
import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/ui/message_handler_registry.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_gatt_services.dart';

class BleGameCentralService implements BleGameService {
  final BluetoothDevice _device;
  List<BluetoothService> _services = [];
  final notificationQueue = Queue<List<int>>();
  bool processing = false;

  StreamSubscription? _gameStateSubscription;
  late final MessageHandlerRegistry _registry;

  BleGameCentralService(this._device);

  @override
  void setRegistry(MessageHandlerRegistry registry) {
    _registry = registry;
  }

  Future<void> discoverDeviceServices() async {
    _services = await _device.discoverServices();
  }

  Future<void> subscribeToGameStateCharacteristic() async {
    Guid gameStateServiceId = Conversions.uuidToGuid(
      BleGattServices.gameStateServiceUuid,
    );
    Guid gameStateCharaId = Conversions.uuidToGuid(
      BleGattServices.gameStateCharacteristic.uuid,
    );
    BluetoothCharacteristic gameStateCharacteristic = _services
        .firstWhere((service) => service.uuid == gameStateServiceId)
        .characteristics
        .firstWhere((chara) => chara.uuid == gameStateCharaId);

    if (!gameStateCharacteristic.isNotifying) {
      await gameStateCharacteristic.setNotifyValue(true);
    }
    log('subscribing to game state characteristic');
    _gameStateSubscription = gameStateCharacteristic.onValueReceived.listen(
      _handleValueReceived,
    );
  }

  void _handleValueReceived(List<int> bytes) async {
    notificationQueue.add(bytes);

    if (processing) return;
    processing = true;

    while (notificationQueue.isNotEmpty) {
      final queueBytes = notificationQueue.removeFirst();
      final handler = _registry.getHandler(queueBytes[0]);
      await handler(Uint8List.fromList(queueBytes));
    }

    processing = false;
  }

  Future<GameSetupMessage> sendSetupRequest() async {
    Guid gameStateServiceId = Conversions.uuidToGuid(
      BleGattServices.gameStateServiceUuid,
    );
    Guid gameStateCharaId = Conversions.uuidToGuid(
      BleGattServices.gameStateCharacteristic.uuid,
    );
    BluetoothCharacteristic gameStateCharacteristic = _services
        .firstWhere((service) => service.uuid == gameStateServiceId)
        .characteristics
        .firstWhere((chara) => chara.uuid == gameStateCharaId);

    List<int> bytes = [];
    await retryRequest(() async {
      bytes = await gameStateCharacteristic.read();
    });

    return GameSetupMessage.fromBytes(Uint8List.fromList(bytes));
  }

  Future<void> _sendToGameStateCharacteristic(BleMessage message) {
    Guid gameStateServiceId = Conversions.uuidToGuid(
      BleGattServices.gameStateServiceUuid,
    );
    Guid gameStateCharaId = Conversions.uuidToGuid(
      BleGattServices.gameStateCharacteristic.uuid,
    );

    BluetoothCharacteristic gameStateCharacteristic = _services
        .firstWhere((service) => service.uuid == gameStateServiceId)
        .characteristics
        .firstWhere((chara) => chara.uuid == gameStateCharaId);

    return retryRequest(() => gameStateCharacteristic.write(message.toBytes()));
  }

  Future<void> sendStartGameRequest() =>
      _sendToGameStateCharacteristic(StartGameMessage());

  @override
  Future<void> sendDrawCardAction(PlayerType player) =>
      _sendToGameStateCharacteristic(DrawCardMessage(player));

  @override
  Future<void> sendPlayCardAction(Card card, PlayerType player) =>
      _sendToGameStateCharacteristic(CardPlayMessage(card, player));

  @override
  Future<void> sendGameResign() =>
      _sendToGameStateCharacteristic(ResignMessage());

  Future<void> retryRequest(Future<void> Function() request) async {
    Exception? error;
    for (int i = 0; i < 3; i++) {
      try {
        return await request();
      } on Exception catch (e) {
        error = e;
      }
    }
    throw error!;
  }

  void dispose() {
    _gameStateSubscription?.cancel();
    _gameStateSubscription = null;
  }
}
