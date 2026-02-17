import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:briscola/ble/ble_game_central_service.dart';
import 'package:briscola/ble/ble_gatt_services.dart';
import 'package:briscola/ble/conversions.dart';
import 'package:briscola/ble/device_connection.dart';
import 'package:briscola/ble/messages/game_setup_message.dart';
import 'package:briscola/ui/screens/client_game_screen.dart';
import 'package:briscola/ui/widgets/scan_result_tile.dart';
import 'package:briscola/snackbar.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<ScanResult> _results = [];

  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  bool _isScanning = false;
  final List<int> _loadingItemsIndexes = [];
  StreamSubscription? _gameCharacteristicSubscription;

  @override
  void initState() {
    super.initState();
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((scanItems) {
      if (mounted) {
        setState(() {
          _results = scanItems;
        });
      }
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((scanState) {
      if (mounted) {
        setState(() {
          _isScanning = scanState;
        });
      }
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    _gameCharacteristicSubscription?.cancel();
    super.dispose();
  }

  Future<void> scanForDevices() async {
    try {
      for (var device in FlutterBluePlus.connectedDevices) {
        device.disconnect();
      }
      final serviceUuid = Guid("12345678-1234-5678-1234-56789abcdef0");
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        withServices: [serviceUuid],
      );
    } catch (e) {
      SnackbarManager.show('An error occurred while starting scan');
    }
    if (mounted) {
      setState(() {});
    }
  }

  void handleDeviceTap(BluetoothDevice device, int index) async {
    setState(() {
      _loadingItemsIndexes.add(index);
    });

    if (device.isConnected) {
      disconnectDevice(device, index);
    } else {
      try {
        await connectToDevice(device, index);
        discoverDeviceServices(device);
      } catch (e) {
        SnackbarManager.show('Error connecting to device');
      } finally {
        setState(() {
          _loadingItemsIndexes.remove(index);
        });
      }
    }
  }

  void disconnectDevice(BluetoothDevice device, int index) async {
    SnackbarManager.show('Disconnecting...');

    try {
      await device.disconnect();
    } catch (e) {
      SnackbarManager.show('Error disconnecting from device.');
    } finally {
      setState(() {
        _loadingItemsIndexes.remove(index);
      });
    }
  }

  Future<void> connectToDevice(BluetoothDevice device, int index) async {
    for (final connectedDevice in FlutterBluePlus.connectedDevices) {
      await connectedDevice.disconnect();
    }
    return device.connect(
      license: License.free,
      timeout: const Duration(seconds: 10),
    );
  }

  void discoverDeviceServices(BluetoothDevice device) async {
    try {
      final List<BluetoothService> services = await device.discoverServices();
      final gameStateServiceId = Conversions.uuidToGuid(
        BleGattServices.gameStateService.uuid,
      );
      final gameLoadedCharacteristicId = Conversions.uuidToGuid(
        BleGattServices.gameLoadedCharacteristic.uuid,
      );

      final BluetoothCharacteristic gameLoadedCharacteristic = services
          .firstWhere((service) => service.uuid == gameStateServiceId)
          .characteristics
          .firstWhere((chara) => chara.uuid == gameLoadedCharacteristicId);
      gameLoadedCharacteristic.setNotifyValue(true);
      _gameCharacteristicSubscription = gameLoadedCharacteristic.onValueReceived
          .listen((data) {
            handleValueReceived(data, device);
          });

      final BluetoothCharacteristic? gameStartCharacteristic = services
          .firstWhere(
            (service) =>
                service.uuid ==
                Conversions.uuidToGuid(BleGattServices.gameStartService.uuid),
          )
          .characteristics
          .firstOrNull;
      await gameStartCharacteristic?.write(Conversions.boolToUint8List(true));
    } catch (e) {
      log(e.toString());
      SnackbarManager.show('Error during connection setup');
    }
  }

  void handleValueReceived(List<int> data, BluetoothDevice device) async {
    if (!mounted) return;

    final centralService = BleGameCentralService(device);
    try {
      final response = await sendGameSetupRequest(centralService);
      centralService.subscribeToGameStateCharacteristic();
      navigateToGamePage(centralService, response, CentralConnection(device));
    } catch (e) {
      SnackbarManager.show('Error during game setup');
    }
  }

  Future<GameSetupMessage> sendGameSetupRequest(
    BleGameCentralService bleGameCentral,
  ) async {
    await bleGameCentral.discoverDeviceServices();
    final response = await bleGameCentral.sendSetupRequest();
    return response;
  }

  void navigateToGamePage(
    BleGameCentralService centralService,
    GameSetupMessage response,
    CentralConnection connection,
  ) {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientGameScreen(
          response.seed,
          response.leadPlayer,
          centralService,
        ),
        settings: RouteSettings(name: '/GameScreen', arguments: connection),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Waiting room'),
      actions: [buildScanButton()],
    ),
    body: buildList(),
  );

  Widget buildScanButton() {
    if (_isScanning) {
      return Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Theme.of(context).disabledColor,
              strokeWidth: 3,
            ),
          ),
          TextButton(onPressed: null, child: const Text('SCAN')),
        ],
      );
    }
    return TextButton(onPressed: scanForDevices, child: const Text('SCAN'));
  }

  Widget buildList() {
    if (_results.isEmpty) {
      return const Center(child: Text('No devices found.'));
    }

    return ListView(
      children: _results
          .asMap()
          .entries
          .map(
            (entry) => ScanResultTile(
              result: entry.value,
              isLoading: _loadingItemsIndexes.contains(entry.key),
              onTap: () => handleDeviceTap(entry.value.device, entry.key),
            ),
          )
          .toList(),
    );
  }
}
