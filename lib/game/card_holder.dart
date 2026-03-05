import 'package:briscola/game/components/card.dart';

abstract interface class CardHolder {
  void acquireCard(Card card);
  Card removeCard(Card card);
}