import 'dart:typed_data';

import 'package:briscola/ble/conversions.dart';
import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/suit.dart';

import 'ble_message.dart';

class CardPlayMessage implements BleMessage {
  final Card card;
  final PlayerType playerType;
  static const int _rankIndex = 0;
  static const int _suitIndex = 1;
  static const int _playerTypeIndex = 2;

  CardPlayMessage(this.card, this.playerType);

  @override
  Uint8List toBytes() {
    final builder = BytesBuilder();
    builder.add(Conversions.rankToUint8List(card.rank));
    builder.add(Conversions.suitTypeToUint8List(card.suit.type));
    builder.add(Conversions.boolToUint8List(playerType == PlayerType.remote));
    return builder.toBytes();
  }

  factory CardPlayMessage.fromBytes(Uint8List bytes) {
    int rank = bytes[_rankIndex];
    SuitType suitType = SuitType.values[bytes[_suitIndex]];
    PlayerType leadPlayer = Conversions.byteToBool(bytes[_playerTypeIndex])
        ? PlayerType.local
        : PlayerType.remote;
    return CardPlayMessage(Card(rank, suitType), leadPlayer);
  }
}
