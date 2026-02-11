import 'dart:async';
import 'dart:typed_data';

import 'package:briscola/ble/ble_game_service.dart';
import 'package:briscola/ble/conversions.dart';
import 'package:briscola/ble/messages/card_play_message.dart';
import 'package:briscola/ble/messages/game_setup_message.dart';
import 'package:briscola/game/components/card.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_gatt_services.dart';

class BleGameCentralService implements BleGameService {
  final BluetoothDevice _device;
  List<BluetoothService> _services = [];

  late final StreamSubscription _gameStateSubscription;
  void Function()? _onDrawCardNotification;
  void Function(CardPlayMessage)? _onPlayCardNotification;

  BleGameCentralService(this._device);

  @override
  void registerOpponentEventHandlers(
    void Function() drawCardCallback,
    void Function(CardPlayMessage) playCardCallback,
  ) {
    _onDrawCardNotification = drawCardCallback;
    _onPlayCardNotification = playCardCallback;
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

  void _handleValueReceived(List<int> bytes) {
    if (bytes.isEmpty) {
      _onDrawCardNotification?.call();
    } else {
      _onPlayCardNotification?.call(
        CardPlayMessage.fromBytes(Uint8List.fromList(bytes)),
      );
    }
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
  Future<void> sendDrawCardAction() {
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

    return retryRequest(() => gameStateCharacteristic.write(List.empty()));
  }

  @override
  Future<void> sendPlayCardAction(Card card) async {
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

    return retryRequest(() async {
      await gameStateCharacteristic.write(
        CardPlayMessage(card).toBytes().toList(),
        withoutResponse: false,
      );
    });
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
