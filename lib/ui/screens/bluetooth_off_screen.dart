import 'dart:io';

import 'package:briscola/snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({super.key, this.adapterState});

  final BluetoothAdapterState? adapterState;

  Widget buildTurnOnButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ElevatedButton(
        child: const Text('TURN ON BLUETOOTH'),
        onPressed: () async {
          try {
            await FlutterBluePlus.turnOn();
          } catch (e) {
            if (context.mounted) {
              SnackbarManager.show('Error turning on bluetooth, try manually.');
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? stateMessage = adapterState?.toString().split('.').last;
    String message = adapterState == BluetoothAdapterState.unknown
        ? 'Bluetooth is not available.'
        : 'Bluetooth is ${stateMessage ?? 'not available'}';

    return Scaffold(
      appBar: AppBar(title: const Text('Waiting room')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth_disabled, size: 100.0),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            if (!kIsWeb && Platform.isAndroid) buildTurnOnButton(context),
          ],
        ),
      ),
    );
  }
}
