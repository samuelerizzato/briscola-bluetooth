import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:briscola/ble/ble_game_service.dart';
import 'package:briscola/ble/conversions.dart';
import 'package:briscola/ble/messages/card_play_message.dart';
import 'package:briscola/ble/messages/draw_card_message.dart';
import 'package:briscola/ble/messages/game_setup_message.dart';
import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/playing_surface.dart';

import 'ble_gatt_services.dart';

class BleGamePeripheralService implements BleGameService {
  final PeripheralManager _manager = PeripheralManager();
  final Central _central;
  late final StreamSubscription _gameStateReadRequestSubscription;
  late final StreamSubscription _gameStateWriteRequestSubscription;
  void Function()? _onResignRequest;
  void Function(DrawCardMessage message)? _onDrawCardWriteRequest;
  Future<void> Function(CardPlayMessage message)? _onPlayCardWriteRequest;
  final int _seed;
  final PlayerType _leadPlayer;

  BleGamePeripheralService(this._central, this._seed, this._leadPlayer);

  @override
  void registerOpponentEventHandlers(
    void Function(DrawCardMessage message) onDrawCard,
    Future<void> Function(CardPlayMessage message) onPlayCard,
    void Function() onResign,
  ) {
    _onDrawCardWriteRequest = onDrawCard;
    _onPlayCardWriteRequest = onPlayCard;
    _onResignRequest = onResign;
  }

  Future<void> setupBleGame() async {
    _gameStateReadRequestSubscription = _manager.characteristicReadRequested
        .listen(handleReadRequest);
    _gameStateWriteRequestSubscription = _manager.characteristicWriteRequested
        .listen(handleWriteRequest);

    await _manager.notifyCharacteristic(
      _central,
      BleGattServices.gameLoadedCharacteristic,
      value: Conversions.boolToUint8List(true),
    );
  }

  void handleReadRequest(GATTCharacteristicReadRequestedEventArgs args) {
    if (_central.uuid != args.central.uuid) {
      _manager.respondReadRequestWithError(
        args.request,
        error: GATTError.insufficientAuthentication,
      );
      return;
    }

    if (args.characteristic.uuid !=
        BleGattServices.gameStateCharacteristicUuid) {
      _manager.respondReadRequestWithError(
        args.request,
        error: GATTError.requestNotSupported,
      );
      return;
    }

    _manager.respondReadRequestWithValue(
      args.request,
      value: GameSetupMessage(_seed, _leadPlayer).toBytes(),
    );
  }

  void handleWriteRequest(
    GATTCharacteristicWriteRequestedEventArgs args,
  ) async {
    log('Received write move request');

    if (_central.uuid != args.central.uuid) {
      await _manager.respondWriteRequestWithError(
        args.request,
        error: GATTError.insufficientAuthentication,
      );
      return;
    }

    if (args.characteristic.uuid !=
        BleGattServices.gameStateCharacteristicUuid) {
      await _manager.respondWriteRequestWithError(
        args.request,
        error: GATTError.requestNotSupported,
      );
      return;
    }

    await _manager.respondWriteRequest(args.request);

    Uint8List bytes = args.request.value;
    if (bytes.isEmpty) {
      _onResignRequest?.call();
    } else if (bytes.length < 2) {
      _onDrawCardWriteRequest?.call(DrawCardMessage.fromBytes(bytes));
    } else {
      _onPlayCardWriteRequest?.call(CardPlayMessage.fromBytes(bytes));
    }
  }

  @override
  Future<void> sendDrawCardAction(PlayerType player) => _retryRequest(
    () => _manager.notifyCharacteristic(
      _central,
      BleGattServices.gameStateCharacteristic,
      value: DrawCardMessage(player).toBytes(),
    ),
  );

  @override
  Future<void> sendPlayCardAction(Card card, PlayerType player) =>
      _retryRequest(
        () => _manager.notifyCharacteristic(
          _central,
          BleGattServices.gameStateCharacteristic,
          value: CardPlayMessage(card, player).toBytes(),
        ),
      );

  @override
  Future<void> sendGameResign() => _retryRequest(
    () => _manager.notifyCharacteristic(
      _central,
      BleGattServices.gameStateCharacteristic,
      value: Uint8List(0),
    ),
  );

  Future<void> _retryRequest(Future<void> Function() request) async {
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
    _gameStateReadRequestSubscription.cancel();
    _gameStateWriteRequestSubscription.cancel();
  }
}
