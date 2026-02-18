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
  final PeripheralManager _manager = PeripheralManager();
  final Central _central;
  bool _isConnected = true;

  PeripheralConnection(this._central);

  @override
  DeviceConnectionSubscription listen(void Function() onDisconnection) =>
      PeripheralConnectionSubscription(
        _manager.connectionStateChanged.listen((event) {
          if (_central.uuid == event.central.uuid &&
              event.state == ConnectionState.disconnected &&
              _isConnected) {
            _isConnected = false;
            onDisconnection();
          }
        }),
        _manager.stateChanged.listen((event) {
          if (event.state == BluetoothLowEnergyState.poweredOff &&
              _isConnected) {
            _isConnected = false;
            onDisconnection();
          }
        }),
      );
}

class PeripheralConnectionSubscription implements DeviceConnectionSubscription {
  final StreamSubscription _adapterStateChangedSubscription;
  final StreamSubscription _connectionStateChangedSubscription;

  PeripheralConnectionSubscription(
    this._connectionStateChangedSubscription,
    this._adapterStateChangedSubscription,
  );

  @override
  void cancel() {
    _connectionStateChangedSubscription.cancel();
    _adapterStateChangedSubscription.cancel();
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
