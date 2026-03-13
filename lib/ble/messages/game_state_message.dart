import 'dart:typed_data';

import 'package:briscola/ble/conversions.dart';
import 'package:briscola/ble/messages/ble_message.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/states/state_machine.dart';

class GameStateMessage implements BleMessage {
  final PlayerType currentPlayer;
  final PlayerType nextPlayer;
  final GamePhase phase;

  final int playerScore;
  final int opponentScore;

  static const int eventType = 3;
  static const int _currentPlayerIndex = 1;
  static const int _nextPlayerIndex = 2;
  static const int _phaseIndex = 3;
  static const int _playerScoreIndex = 4;
  static const int _opponentScoreIndex = 5;

  GameStateMessage(
    this.currentPlayer,
    this.nextPlayer,
    this.phase,
    this.playerScore,
    this.opponentScore,
  );

  @override
  Uint8List toBytes() {
    final builder = BytesBuilder();
    builder.addByte(eventType);
    builder.add(
      Conversions.boolToUint8List(currentPlayer == PlayerType.remote),
    );
    builder.add(Conversions.boolToUint8List(nextPlayer == PlayerType.remote));
    builder.addByte(phase.index);
    builder.addByte(playerScore);
    builder.addByte(opponentScore);
    return builder.toBytes();
  }

  factory GameStateMessage.fromBytes(Uint8List bytes) => GameStateMessage(
    Conversions.byteToBool(bytes[_currentPlayerIndex])
        ? PlayerType.local
        : PlayerType.remote,
    Conversions.byteToBool(bytes[_nextPlayerIndex])
        ? PlayerType.local
        : PlayerType.remote,
    GamePhase.values[bytes[_phaseIndex]],
    bytes[_playerScoreIndex],
    bytes[_opponentScoreIndex],
  );
}
