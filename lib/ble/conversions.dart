import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:briscola/game/rank.dart';
import 'package:briscola/game/suit.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Conversions {
  Conversions._();

  static Uint8List suitTypeToUint8List(SuitType type) =>
      Uint8List(1)..[0] = type.index;

  static Uint8List rankToUint8List(Rank rank) =>
      Uint8List(1)..[0] = rank.value;

  static Uint8List intToUint8List(int number) =>
      Uint8List(1)..[0] = number;

  static Uint8List boolToUint8List(bool condition) =>
      Uint8List(1)..[0] = condition ? 1 : 0;

  static bool byteToBool(int byte) => byte == 1;

  static Guid uuidToGuid(UUID uuid) => Guid.fromBytes(uuid.value);

  /*static Uint8List gameStateToUint8List(GameState state) =>
      Uint8List(1)..[0] = state.index;*/
}
