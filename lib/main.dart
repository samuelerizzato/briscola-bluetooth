import 'dart:developer';

import 'package:briscola/ble/device_connection.dart';
import 'package:briscola/ui/screens/home_screen.dart';
import 'package:briscola/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  runApp(
    MaterialApp(
      title: 'Briscola',
      theme: ThemeData(fontFamily: 'LilitaOne'),
      home: const HomeScreen(),
      navigatorObservers: [BluetoothAdapterStateObserver()],
      scaffoldMessengerKey: SnackbarManager.scaffoldKey,
    ),
  );
}

class BluetoothAdapterStateObserver extends NavigatorObserver {
  DeviceConnectionSubscription? _connectionSubscription;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == '/GameScreen' &&
        previousRoute?.settings.name != "/") {
      final connection = route.settings.arguments as DeviceConnection;
      _connectionSubscription ??= connection.listen(() {
        navigator?.pop();
        SnackbarManager.show("Connection lost");
      });
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
  }
}
