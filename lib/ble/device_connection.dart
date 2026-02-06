import 'dart:async';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract interface class DeviceConnection {
  DeviceConnectionSubscription listen(void Function() onDisconnection);
}

abstract interface class DeviceConnectionSubscription {
  void cancel();
}

class PeripheralConnection implements DeviceConnection {
  final PeripheralManager _peripheralManager = PeripheralManager();
  final Central _central;

  PeripheralConnection(this._central);

  @override
  DeviceConnectionSubscription listen(void Function() onDisconnection) =>
      PeripheralConnectionSubscription(
        _peripheralManager.connectionStateChanged.listen((event) {
          if (_central.uuid == event.central.uuid &&
              event.state == ConnectionState.disconnected) {
            onDisconnection();
          }
        }),
      );
}

class PeripheralConnectionSubscription implements DeviceConnectionSubscription {
  final StreamSubscription _connectionStateChangedSubscription;

  PeripheralConnectionSubscription(this._connectionStateChangedSubscription);

  @override
  void cancel() {
    _connectionStateChangedSubscription.cancel();
  }
}

class CentralConnection implements DeviceConnection {
  final BluetoothDevice _peripheral;

  CentralConnection(this._peripheral);

  @override
  DeviceConnectionSubscription listen(void Function() onDisconnection) =>
      CentralConnectionSubscription(
        _peripheral.connectionState.listen((event) {
          if (event == BluetoothConnectionState.disconnected) {
            onDisconnection();
          }
        }),
      );
}

class CentralConnectionSubscription implements DeviceConnectionSubscription {
  final StreamSubscription _connectionStateSubscription;

  CentralConnectionSubscription(this._connectionStateSubscription);

  @override
  void cancel() {
    _connectionStateSubscription.cancel();
  }
}