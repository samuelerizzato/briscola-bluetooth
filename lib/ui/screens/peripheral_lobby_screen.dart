import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:briscola/ble/ble_gatt_services.dart';
import 'package:briscola/ble/conversions.dart';
import 'package:briscola/ble/device_connection.dart';
import 'package:briscola/snackbar.dart';
import 'package:briscola/ui/screens/host_game_screen.dart';
import 'package:flutter/material.dart' hide ConnectionState;

class PeripheralLobbyScreen extends StatefulWidget {
  const PeripheralLobbyScreen({super.key});

  @override
  State<StatefulWidget> createState() => _PeripheralLobbyScreenState();
}

class _PeripheralLobbyScreenState extends State<PeripheralLobbyScreen> {
  bool _isAdvertising = false;
  final PeripheralManager _manager = PeripheralManager();
  late final StreamSubscription _stateChangedSubscription;
  late final StreamSubscription _connectionStateChangedSubscription;
  late StreamSubscription _characteristicWriteRequestedSubscription;
  BluetoothLowEnergyState _bleState = BluetoothLowEnergyState.unknown;
  Central? _central;
  bool _isCentralReady = false;
  final String _hostName = 'HOST-1234';

  @override
  void initState() {
    super.initState();
    _bleState = _manager.state;
    _stateChangedSubscription = _manager.stateChanged.listen(
      _handleManagerStateChange,
    );
    _connectionStateChangedSubscription = _manager.connectionStateChanged
        .listen(_handleConnectionStateChange);

    _characteristicWriteRequestedSubscription = _manager
        .characteristicWriteRequested
        .listen(_handleWriteRequest);
  }

  void _handleWriteRequest(
    GATTCharacteristicWriteRequestedEventArgs args,
  ) async {
    if (!mounted) {
      await _manager.respondWriteRequestWithError(
        args.request,
        error: GATTError.unlikelyError,
      );
      return;
    }

    if (_central?.uuid != args.central.uuid) {
      await _manager.respondWriteRequestWithError(
        args.request,
        error: GATTError.insufficientAuthentication,
      );
      return;
    }

    if (args.characteristic.uuid !=
        BleGattServices.gameStartCharacteristic.uuid) {
      await _manager.respondWriteRequestWithError(
        args.request,
        error: GATTError.requestNotSupported,
      );
      return;
    }

    dev.log('received write on chara 200');

    bool isReady = Conversions.byteToBool(args.request.value.first);
    setState(() {
      _isCentralReady = isReady;
    });

    await _manager.respondWriteRequest(args.request);
  }

  void _handleManagerStateChange(
    BluetoothLowEnergyStateChangedEventArgs args,
  ) async {
    if (!mounted) {
      return;
    }

    if (args.state != BluetoothLowEnergyState.poweredOn) {
      setState(() {
        _isAdvertising = false;
        _central = null;
      });
    }

    setState(() {
      _bleState = args.state;
    });

    if (args.state == BluetoothLowEnergyState.unauthorized &&
        Platform.isAndroid) {
      await _manager.authorize();
    }
  }

  void _handleConnectionStateChange(
    CentralConnectionStateChangedEventArgs args,
  ) {
    if (!mounted) {
      return;
    }

    switch (args.state) {
      case ConnectionState.disconnected:
        if (_central?.uuid == args.central.uuid) {
          setState(() {
            _central = null;
            _isCentralReady = false;
          });
        }
      case ConnectionState.connected:
        if (_central == null) {
          setState(() {
            _central = args.central;
          });
          _stopAdvertising();
        } else {
          _manager.disconnect(args.central);
        }
    }
  }

  @override
  void dispose() {
    _stateChangedSubscription.cancel();
    _connectionStateChangedSubscription.cancel();
    _characteristicWriteRequestedSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget screen = _bleState == BluetoothLowEnergyState.poweredOn
        ? _buildWaitingScreen()
        : _buildBluetoothOffScreen();

    return Scaffold(
      appBar: AppBar(title: const Text('Waiting room')),
      body: screen,
    );
  }

  Widget _buildBluetoothOffScreen() {
    String message;
    switch (_bleState) {
      case BluetoothLowEnergyState.unsupported:
        message = 'Bluetooth is off or not supported.';
      case BluetoothLowEnergyState.unauthorized:
        message = 'This app is not authorized to access bluetooth.';
      default:
        message = 'Bluetooth is not available.';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bluetooth_disabled, size: 100.0),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10.0,
        children: [
          Text(
            'You are $_hostName',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          _central == null
              ? RichText(
                  text: TextSpan(
                    children: [
                      WidgetSpan(child: Icon(Icons.person_off_outlined)),
                      TextSpan(
                        text: 'No player connected',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : Column(
                  spacing: 2.0,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          WidgetSpan(child: Icon(Icons.person_outlined)),
                          TextSpan(
                            text: 'Player connected',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: Text('Identifier'),
                    ),
                    Center(
                      child: Text(_central!.uuid.toString()),
                    ),
                  ],
                ),
          ElevatedButton(
            child: Text(_isAdvertising ? 'STOP SEARCH' : 'SEARCH PLAYERS'),
            onPressed: () {
              if (_isAdvertising) {
                _stopAdvertising();
              } else {
                _startAdvertising();
              }
            },
          ),
          ElevatedButton(
            onPressed: _central != null ? _startGame : null,
            child: Text('START GAME'),
          ),
        ],
      ),
    );
  }

  Future<void> _startAdvertising() async {
    if (_isAdvertising) {
      return;
    }

    if (_central != null) {
      await _manager.disconnect(_central!);
    }
    await _manager.removeAllServices();
    await _manager.addService(BleGattServices.gameStartService);
    await _manager.addService(BleGattServices.gameStateService);

    final advertisement = Advertisement(
      serviceUUIDs: [UUID.fromString("12345678-1234-5678-1234-56789abcdef0")],
      name: Platform.isWindows ? null : _hostName,
      manufacturerSpecificData: Platform.isIOS || Platform.isMacOS
          ? []
          : [
              ManufacturerSpecificData(
                id: 0x2e19,
                data: Uint8List.fromList([0x01, 0x02, 0x03]),
              ),
            ],
    );

    await _manager.startAdvertising(advertisement);
    setState(() {
      _isAdvertising = true;
      _central = null;
    });
  }

  Future<void> _stopAdvertising() async {
    if (!_isAdvertising) {
      return;
    }

    await _manager.stopAdvertising();
    setState(() {
      _isAdvertising = false;
    });
  }

  void _startGame() async {
    if (!_isCentralReady) {
      SnackbarManager.show("Cannot start game, wait and try again");
      return;
    }

    await _characteristicWriteRequestedSubscription.cancel();
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HostGameScreen(_central!),
          settings: RouteSettings(
            name: '/GameScreen',
            arguments: PeripheralConnection(_central!),
          ),
        ),
      );
    }

    if (mounted) {
      _characteristicWriteRequestedSubscription = _manager
          .characteristicWriteRequested
          .listen(_handleWriteRequest);
    }
  }
}
