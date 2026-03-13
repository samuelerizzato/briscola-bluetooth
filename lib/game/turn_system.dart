import 'dart:async';

import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/deck_pile.dart';
import 'package:briscola/game/components/hand.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/states/game_state.dart';
import 'package:briscola/game/states/state_machine.dart';
import 'package:briscola/game/suit.dart';

class TurnSystem {
  final StateMachine _stateMachine;
  final PlayingSurface surface;
  final DeckPile _deck;

  final SuitType _briscolaType;

  StreamSubscription<void>? _deckChangedSubscription;
  StreamSubscription<void>? _surfaceChangedSubscription;

  TurnSystem(this._stateMachine, this.surface, this._deck, this._briscolaType) {
    _surfaceChangedSubscription = surface.surfaceChanges.listen(
      _handlePlayPhaseEnd,
    );
    _deckChangedSubscription = _deck.deckChanges.listen(_handleDrawPhaseEnd);
  }

  void dispose() {
    _surfaceChangedSubscription?.cancel();
    _deckChangedSubscription?.cancel();
  }

  void _handleDrawPhaseEnd(void event) {
    final currentState = _stateMachine.currentState;

    if (currentState.nextHand.canAcquireCard()) {
      _stateMachine.transitionTo(
        currentState.copyWith(
          currentHand: currentState.nextHand,
          nextHand: currentState.currentHand,
        ),
      );
      return;
    }

    _stateMachine.transitionTo(
      currentState.copyWith(
        currentHand: currentState.nextHand,
        nextHand: currentState.currentHand,
        phase: GamePhase.play,
      ),
    );
  }

  void _handlePlayPhaseEnd(void event) {
    if (!surface.canAcquireCard(_stateMachine.currentState.nextHand.type)) {
      _handleTrickEnd(_stateMachine.currentState);
      return;
    }

    _stateMachine.transitionTo(
      _stateMachine.currentState.copyWith(
        currentHand: _stateMachine.currentState.nextHand,
        nextHand: _stateMachine.currentState.currentHand,
      ),
    );
  }

  void _handleTrickEnd(GameState endTrickState) {
    PlayerType winner = _decideTrickWinner(
      surface.playerCard!,
      surface.opponentCard!,
      _briscolaType,
      endTrickState.nextHand.type,
    );

    Hand winnerHand;
    Hand loserHand;

    if (winner == endTrickState.currentHand.type) {
      winnerHand = endTrickState.currentHand;
      loserHand = endTrickState.nextHand;
    } else {
      winnerHand = endTrickState.nextHand;
      loserHand = endTrickState.currentHand;
    }

    int playerScore = endTrickState.playerScore;
    int opponentScore = endTrickState.opponentScore;
    int trickScore =
        surface.playerCard!.rank.points + surface.opponentCard!.rank.points;
    if (winner == PlayerType.local) {
      playerScore += trickScore;
    } else {
      opponentScore += trickScore;
    }

    _stateMachine.transitionTo(
      GameState(
        winnerHand,
        loserHand,
        GamePhase.trickEnd,
        playerScore,
        opponentScore,
      ),
    );
  }

  PlayerType _decideTrickWinner(
    Card playerCard,
    Card opponentCard,
    SuitType briscolaSuit,
    PlayerType leadPlayer,
  ) {
    if (playerCard.suit.type == opponentCard.suit.type) {
      return playerCard.rank.compareTo(opponentCard.rank) > 0
          ? PlayerType.local
          : PlayerType.remote;
    }

    if (playerCard.suit.type == briscolaSuit) {
      return PlayerType.local;
    }

    if (opponentCard.suit.type == briscolaSuit) {
      return PlayerType.remote;
    }

    return leadPlayer;
  }

  void decideNextTurn() {
    GamePhase nextPhase;

    if (_stateMachine.currentState.currentHand.isEmpty) {
      nextPhase = GamePhase.gameOver;
    } else if (_deck.isEmpty) {
      nextPhase = GamePhase.play;
    } else {
      nextPhase = GamePhase.draw;
    }

    _stateMachine.transitionTo(
      _stateMachine.currentState.copyWith(phase: nextPhase),
    );
  }

  bool canDraw(PlayerType playerType) =>
      _stateMachine.currentState.phase == GamePhase.draw &&
      _stateMachine.currentState.currentHand.type == playerType;

  bool canPlay(PlayerType playerType) =>
      _stateMachine.currentState.phase == GamePhase.play &&
      _stateMachine.currentState.currentHand.type == playerType;
}
