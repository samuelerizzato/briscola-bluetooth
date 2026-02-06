import 'dart:async';

import 'package:briscola/ui/screens/bluetooth_off_screen.dart';
import 'package:briscola/ui/screens/scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class CentralLobbyScreen extends StatefulWidget {
  const CentralLobbyScreen({super.key});

  @override
  State<StatefulWidget> createState() => _CentralLobbyScreenState();
}

class _CentralLobbyScreenState extends State<CentralLobbyScreen> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;

  @override
  void initState() {
    super.initState();
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _adapterStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget screen = _adapterState == BluetoothAdapterState.on
        ? const ScanScreen()
        : BluetoothOffScreen(adapterState: _adapterState,);

    return screen;
  }
}
