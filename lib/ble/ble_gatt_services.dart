import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

class BleGattServices {
  static final UUID gameStartServiceUuid = UUID.short(100);
  static final UUID gameStartCharacteristicUuid = UUID.short(200);

  static final GATTService _gameStartService = GATTService(
    uuid: gameStartServiceUuid,
    isPrimary: true,
    includedServices: [],
    characteristics: [
      GATTCharacteristic.mutable(
        uuid: gameStartCharacteristicUuid,
        properties: [
          GATTCharacteristicProperty.read,
          GATTCharacteristicProperty.write,
          GATTCharacteristicProperty.indicate,
        ],
        permissions: [
          GATTCharacteristicPermission.read,
          GATTCharacteristicPermission.write,
        ],
        descriptors: [],
      ),
    ],
  );

  static GATTService get gameStartService => _gameStartService;

  static GATTCharacteristic get gameStartCharacteristic =>
      _gameStartService.characteristics.first;

  static final UUID gameStateServiceUuid = UUID.short(101);
  static final UUID gameLoadedCharacteristicUuid = UUID.short(201);
  static final UUID gameStateCharacteristicUuid = UUID.short(202);

  static final GATTService _gameStateService = GATTService(
    uuid: gameStateServiceUuid,
    isPrimary: true,
    includedServices: [],
    characteristics: [
      GATTCharacteristic.mutable(
        uuid: gameLoadedCharacteristicUuid,
        properties: [
          GATTCharacteristicProperty.read,
          GATTCharacteristicProperty.indicate,
        ],
        permissions: [GATTCharacteristicPermission.read],
        descriptors: [],
      ),
      GATTCharacteristic.mutable(
        uuid: gameStateCharacteristicUuid,
        properties: [
          GATTCharacteristicProperty.read,
          GATTCharacteristicProperty.write,
          GATTCharacteristicProperty.indicate,
        ],
        permissions: [
          GATTCharacteristicPermission.read,
          GATTCharacteristicPermission.write,
        ],
        descriptors: [],
      ),
    ],
  );

  static GATTService get gameStateService => _gameStateService;

  static GATTCharacteristic get gameLoadedCharacteristic => _gameStateService
      .characteristics
      .firstWhere((chara) => chara.uuid == gameLoadedCharacteristicUuid);

  static GATTCharacteristic get gameStateCharacteristic => _gameStateService
      .characteristics
      .firstWhere((chara) => chara.uuid == gameStateCharacteristicUuid);
}
