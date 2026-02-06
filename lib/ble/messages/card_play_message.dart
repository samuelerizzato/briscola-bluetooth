import 'dart:typed_data';

import 'package:briscola/ble/conversions.dart';
import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/suit.dart';

import 'ble_message.dart';

class CardPlayMessage implements BleMessage {
  final Card card;
  static const int rankIndex = 0;
  static const int suitIndex = 1;

  CardPlayMessage(this.card);

  @override
  Uint8List toBytes() {
    final builder = BytesBuilder();
    builder.add(Conversions.rankToUint8List(card.rank));
    builder.add(Conversions.suitTypeToUint8List(card.suit.type));
    return builder.toBytes();
  }

  factory CardPlayMessage.fromBytes(Uint8List bytes) {
    int rank = bytes[rankIndex];
    SuitType suitType = SuitType.values[bytes[suitIndex]];
    return CardPlayMessage(Card(rank, suitType));
  }
}