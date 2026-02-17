import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:typed_data';

import 'package:briscola/ble/ble_game_service.dart';
import 'package:briscola/ble/conversions.dart';
import 'package:briscola/ble/messages/card_play_message.dart';
import 'package:briscola/ble/messages/draw_card_message.dart';
import 'package:briscola/ble/messages/game_setup_message.dart';
import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_gatt_services.dart';

class BleGameCentralService implements BleGameService {
  final BluetoothDevice _device;
  List<BluetoothService> _services = [];
  final notificationQueue = Queue<List<int>>();
  bool processing = false;

  late final StreamSubscription _gameStateSubscription;
  void Function()? _onOpponentResignNotification;
  void Function(DrawCardMessage message)? _onDrawCardNotification;
  Future<void> Function(CardPlayMessage message)? _onPlayCardNotification;

  BleGameCentralService(this._device);

  @override
  void registerOpponentEventHandlers(
    void Function(DrawCardMessage message) onDrawCard,
    Future<void> Function(CardPlayMessage message) onPlayCard,
    void Function() onResign,
  ) {
    _onDrawCardNotification = onDrawCard;
    _onPlayCardNotification = onPlayCard;
    _onOpponentResignNotification = onResign;
  }

  Future<void> discoverDeviceServices() async {
    _services = await _device.discoverServices();
  }

  void subscribeToGameStateCharacteristic() async {
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

    await gameStateCharacteristic.setNotifyValue(true);
    _gameStateSubscription = gameStateCharacteristic.onValueReceived.listen(
      _handleValueReceived,
    );
  }

  void _handleValueReceived(List<int> bytes) async {
    notificationQueue.add(bytes);
    log('Processing value $processing');
    if (processing) return;
    processing = true;

    while (notificationQueue.isNotEmpty) {
      final notificationBytes = notificationQueue.removeFirst();
      if (notificationBytes.isEmpty) {
        _onOpponentResignNotification?.call();
      } else if (notificationBytes.length < 2) {
        _onDrawCardNotification?.call(
          DrawCardMessage.fromBytes(Uint8List.fromList(notificationBytes)),
        );
      } else {
        await _onPlayCardNotification?.call(
          CardPlayMessage.fromBytes(Uint8List.fromList(notificationBytes)),
        );
      }
    }
    log('exiting value received');
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

  @override
  Future<void> sendDrawCardAction(PlayerType player) {
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

    return retryRequest(
      () => gameStateCharacteristic.write(DrawCardMessage(player).toBytes()),
    );
  }

  @override
  Future<void> sendPlayCardAction(Card card, PlayerType player) async {
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

    return retryRequest(
      () => gameStateCharacteristic.write(
        CardPlayMessage(card, player).toBytes().toList(),
      ),
    );
  }

  @override
  Future<void> sendGameResign() {
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

    return retryRequest(() => gameStateCharacteristic.write([]));
  }

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
    _gameStateSubscription.cancel();
  }
}
