import 'package:briscola/game/components/hand.dart';
import 'package:briscola/game/states/state_machine.dart';

class GameState {
  final Hand currentHand;
  final Hand nextHand;
  final GamePhase phase;

  final int playerScore;
  final int opponentScore;

  GameState(
    this.currentHand,
    this.nextHand,
    this.phase,
    this.playerScore,
    this.opponentScore,
  );

  GameState copyWith({
    Hand? currentHand,
    Hand? nextHand,
    GamePhase? phase,
    int? playerScore,
    int? opponentScore,
  }) => GameState(
    currentHand ?? this.currentHand,
    nextHand ?? this.nextHand,
    phase ?? this.phase,
    playerScore ?? this.playerScore,
    opponentScore ?? this.opponentScore,
  );
}
