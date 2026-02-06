import 'package:flutter/material.dart';

class SnackbarManager {
  static final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  static get scaffoldKey => _scaffoldKey;

  static void show(String message) {
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(content: Text(message))
    );
  }
}