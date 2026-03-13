import 'dart:async';
import 'package:flutter/animation.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import 'package:briscola/game/commands/command_invoker.dart';
import 'package:briscola/game/commands/move_command.dart';
import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/deck_pile.dart';
import 'package:briscola/game/components/hand.dart';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/components/tricks_pile.dart';

class GameActions {
  final PlayingSurface _surface;
  final DeckPile _deck;
  final TricksPile _playerTricksPile;
  final TricksPile _opponentTricksPile;

  GameActions(
    this._surface,
    this._deck,
    this._playerTricksPile,
    this._opponentTricksPile,
  );

  void playCard(Hand hand, Card card) {
    _surface.setActiveSlot(hand.type);
    CommandInvoker.execute(MoveCommand(hand, _surface, card));
  }

  void drawCard(Hand hand) {
    CommandInvoker.execute(MoveCommand(_deck, hand, _deck.topCard));
  }

  Future<void> animateTrickEnd(PlayerType winner) {
    TricksPile winnerPile = winner == PlayerType.local
        ? _playerTricksPile
        : _opponentTricksPile;

    final completer = Completer<void>();

    _addMoveEffectToCard(_surface.playerCard!, winnerPile.position, () {
      CommandInvoker.execute(
        MoveCommand(_surface, winnerPile, _surface.playerCard!),
      );
      if (_surface.playerCard == null && _surface.opponentCard == null) {
        completer.complete();
      }
    });

    _addMoveEffectToCard(_surface.opponentCard!, winnerPile.position, () {
      CommandInvoker.execute(
        MoveCommand(_surface, winnerPile, _surface.opponentCard!),
      );
      if (_surface.playerCard == null && _surface.opponentCard == null) {
        completer.complete();
      }
    });

    return completer.future;
  }

  void _addMoveEffectToCard(Card card, Vector2 to, VoidCallback onComplete) {
    final dt = (to - card.position).length / (10.0 * card.width);
    card.add(
      MoveToEffect(
        to,
        EffectController(
          duration: dt,
          startDelay: 1.25,
          curve: Curves.easeOutQuad,
        ),
        onComplete: onComplete,
      ),
    );
  }
}
