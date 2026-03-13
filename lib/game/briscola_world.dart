import 'dart:async';
import 'dart:math';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';

import 'package:briscola/game/rank.dart';
import 'package:briscola/game/states/game_context.dart';
import 'package:briscola/game/states/state_machine.dart';
import 'package:briscola/game/briscola_game.dart';
import 'package:briscola/game/suit.dart';
import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/hand.dart';

class BriscolaWorld extends World with HasGameReference<BriscolaGame> {
  static const double boardWidth = 400.0;
  static const double boardHeight = 900.0;
  static const double cardWidth = 90.0;
  static const double cardHeight = 150.0;
  static const double cardGap = 20.0;
  static final Vector2 cardSize = Vector2(cardWidth, cardHeight);
  static const double cardRadius = 10.0;
  static const double surfacePadding = 10.0;
  static final Vector2 surfaceSize = Vector2(
    cardWidth * 2.0 + cardGap + surfacePadding * 2.0,
    cardHeight + surfacePadding * 2.0,
  );

  final List<Card> _cards = [];
  final int _initialSeed;
  final StateMachine _stateMachine;
  final GameContext _gameContext;
  final void Function()? _onSetup;

  BriscolaWorld(
    this._initialSeed,
    this._stateMachine,
    this._gameContext, [
    this._onSetup,
  ]);

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    await Flame.images.loadAll([
      'baton.png',
      'coin.png',
      'cup.png',
      'sword.png',
      'jack.png',
      'knight.png',
      'king.png',
    ]);

    _gameContext.deck
      ..priority = 41
      ..size = cardSize
      ..position = Vector2(0.0, boardHeight - cardHeight * 2.0 - cardGap);

    _gameContext.playingSurface
      ..size = surfaceSize
      ..position = Vector2(
        boardWidth / 2.0 - (cardWidth + cardGap / 2.0),
        boardHeight / 2.0 - (cardHeight / 2.0),
      );

    _gameContext.playerHand
      ..size = Vector2(cardWidth * 3.0 + cardGap * 2.0, cardHeight)
      ..position = Vector2(
        boardWidth / 2.0 - ((cardWidth * 3.0) / 2.0 + cardGap),
        boardHeight - cardHeight,
      );

    _gameContext.opponentHand
      ..size = Vector2(cardWidth * 3.0 + cardGap * 2.0, cardHeight)
      ..position = Vector2(
        boardWidth / 2.0 - ((cardWidth * 3.0) / 2.0 + cardGap),
        0,
      );

    _gameContext.playerTricksPile
      ..size = cardSize
      ..priority = 41
      ..position = Vector2(
        boardWidth - cardWidth,
        _gameContext.playerHand.y - cardHeight - cardGap,
      );

    _gameContext.opponentTricksPile
      ..size = cardSize
      ..priority = 41
      ..position = Vector2(
        boardWidth - cardWidth,
        _gameContext.opponentHand.y + cardHeight + cardGap,
      );

    add(_gameContext.deck);
    add(_gameContext.playingSurface);
    add(_gameContext.playerHand);
    add(_gameContext.opponentHand);
    add(_gameContext.playerTricksPile);
    add(_gameContext.opponentTricksPile);
    setup();
  }

  Future<void> setup() async {
    _initCards(_initialSeed);
    _dealCards(_initialSeed);
    _initCamera();
    _onSetup?.call();
  }

  void _initCards(int seed) {
    for (int rank = Rank.minValue; rank <= Rank.maxValue; rank++) {
      for (SuitType type in SuitType.values) {
        _cards.add(Card(rank, type));
      }
    }
    _cards.shuffle(Random(seed));
    addAll(_cards);
  }

  void _dealCards(int seed) {
    Hand hand = _stateMachine.currentState.currentHand;
    int lastCardIndex = _cards.length - 1;
    for (int i = 0; i < hand.maxSize; i++) {
      hand.acquireCard(_cards[lastCardIndex - i]);
    }

    lastCardIndex -= hand.maxSize;
    hand = _stateMachine.currentState.nextHand;

    for (int i = 0; i < hand.maxSize; i++) {
      hand.acquireCard(_cards[lastCardIndex - i]);
    }

    lastCardIndex -= hand.maxSize;

    List<Card> restCards = _cards.sublist(0, lastCardIndex + 1);
    List<int> briscolaSuitIndexes = [];
    for (int i = 0; i < restCards.length; i++) {
      _gameContext.deck.acquireCard(restCards[i]);
      if (restCards[i].suit.type == _gameContext.briscolaSuit) {
        briscolaSuitIndexes.add(i);
      }
    }

    int randomIndex = Random(seed).nextInt(briscolaSuitIndexes.length);
    _gameContext.deck.setBriscola(briscolaSuitIndexes[randomIndex]);
  }

  void _initCamera() {
    game.camera.viewfinder.visibleGameSize = Vector2(boardWidth, boardHeight);
    game.camera.viewfinder.position = Vector2(
      boardWidth / 2.0,
      boardHeight / 2.0,
    );
    game.camera.viewfinder.anchor = Anchor.center;
  }
}
