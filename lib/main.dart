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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'LilitaOne',
        appBarTheme: AppBarThemeData(
          backgroundColor: Colors.black.withAlpha(0x33),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.dark,
        ).copyWith(surface: const Color(0xFF13663F), onSurface: Colors.white),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        ),
        listTileTheme: ListTileThemeData(
          iconColor: Colors.white,
          tileColor: Colors.black.withAlpha(0x33),
          subtitleTextStyle: TextStyle(
            color: const Color(0xFFFDEBD6),
            fontFamily: 'LilitaOne',
          ),
        ),
      ),
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
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute?.settings.name == '/GameScreen') {
      _connectionSubscription?.cancel();
      _connectionSubscription = null;
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (route.settings.name == '/GameScreen') {
      _connectionSubscription?.cancel();
      _connectionSubscription = null;
    }
  }
}
