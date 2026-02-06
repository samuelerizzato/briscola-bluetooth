import 'dart:async';
import 'dart:math';

import 'package:briscola/game/components/deck_pile.dart';
import 'package:briscola/game/components/player_hand.dart';
import 'package:briscola/game/components/tricks_pile.dart';
import 'package:briscola/game/states/game_state.dart';
import 'package:briscola/game/rank.dart';
import 'package:briscola/game/states/game_context.dart';
import 'package:briscola/game/states/state_machine.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';
import 'package:briscola/game/briscola_game.dart';
import 'package:briscola/game/suit.dart';
import 'package:briscola/game/components/card.dart';
import 'package:briscola/game/components/playing_surface.dart';

import 'components/hand.dart';

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
  late final StateMachine _stateMachine;

  GameContext get _gameContext => _stateMachine.context;

  DeckPile get _deck => _stateMachine.context.deck;

  PlayingSurface get _surface => _stateMachine.context.playingSurface;

  PlayerHand get _playerHand => _stateMachine.context.playerHand;

  Hand get _opponentHand => _stateMachine.context.opponentHand;

  TricksPile get _playerTricksPile => _stateMachine.context.playerTricksPile;

  TricksPile get _opponentTricksPile =>
      _stateMachine.context.opponentTricksPile;

  BriscolaWorld(this._initialSeed, this._stateMachine);

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

    _deck
      ..onDrawCard = handlePlayerDraw
      ..priority = 41
      ..size = cardSize
      ..position = Vector2(0.0, boardHeight - cardHeight * 2.0 - cardGap);

    _surface
      ..size = surfaceSize
      ..position = Vector2(
        boardWidth / 2.0 - (cardWidth + cardGap / 2.0),
        boardHeight / 2.0 - (cardHeight / 2.0),
      );

    _playerHand
      ..size = Vector2(cardWidth * 3.0 + cardGap * 2.0, cardHeight)
      ..position = Vector2(
        boardWidth / 2.0 - ((cardWidth * 3.0) / 2.0 + cardGap),
        boardHeight - cardHeight,
      );

    _opponentHand
      ..size = Vector2(cardWidth * 3.0 + cardGap * 2.0, cardHeight)
      ..position = Vector2(
        boardWidth / 2.0 - ((cardWidth * 3.0) / 2.0 + cardGap),
        0,
      );

    _playerTricksPile
      ..size = cardSize
      ..priority = 41
      ..position = Vector2(
        boardWidth - cardWidth,
        _playerHand.y - cardHeight - cardGap,
      );

    _opponentTricksPile
      ..size = cardSize
      ..priority = 41
      ..position = Vector2(
        boardWidth - cardWidth,
        _opponentHand.y + cardHeight + cardGap,
      );

    add(_deck);
    add(_surface);
    add(_playerHand);
    add(_opponentHand);
    add(_playerTricksPile);
    add(_opponentTricksPile);
    setup();

    GameState initialState = _gameContext.leadPlayer == PlayerType.local
        ? _stateMachine.playerTurnState
        : _stateMachine.opponentTurnState;
    _stateMachine.initialize(initialState);
  }

  Future<void> setup() async {
    _initCards(_initialSeed);
    _dealCards(_initialSeed);
    _initCamera();
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

  void _initCamera() {
    game.camera.viewfinder.visibleGameSize = Vector2(boardWidth, boardHeight);
    game.camera.viewfinder.position = Vector2(
      boardWidth / 2.0,
      boardHeight / 2.0,
    );
    game.camera.viewfinder.anchor = Anchor.center;
  }

  void _dealCards(int seed) {
    Hand hand = _gameContext.leadPlayer == PlayerType.local
        ? _playerHand
        : _opponentHand;
    int lastCardIndex = _cards.length - 1;
    for (int i = 0; i < hand.maxSize; i++) {
      hand.acquireCard(_cards[lastCardIndex - i]);
    }

    lastCardIndex -= hand.maxSize;
    hand = _gameContext.leadPlayer == PlayerType.local
        ? _opponentHand
        : _playerHand;

    for (int i = 0; i < hand.maxSize; i++) {
      hand.acquireCard(_cards[lastCardIndex - i]);
    }

    lastCardIndex -= hand.maxSize;

    List<Card> restCards = _cards.sublist(0, lastCardIndex + 1);
    for (var card in restCards) {
      _deck.acquireCard(card);
    }

    int index = Random(seed).nextInt(restCards.length);
    _gameContext.briscolaSuit = restCards[index].suit.type;
    _deck.setBriscola(index);
  }

  Future<void> onLocalPlayCard(Card card) async {
    _playCard(_playerHand, card);
  }

  void onRemotePlayCard(Card card) {
    Card handCard = _opponentHand.cards.firstWhere(
      (c) => c.rank.value == card.rank.value && c.suit.type == card.suit.type,
    );
    handCard.flip();
    _playCard(_opponentHand, handCard);
  }

  void _playCard(Hand hand, Card card) {
    if (hand.isEnabled && _surface.canAcquireCard(hand.type)) {
      hand.removeCard(card);
      _surface.acquireCard(card, hand.type);
    }
    _stateMachine.transitionTo(_stateMachine.turnEndState);
  }

  Future<void> handlePlayerDraw() async {
    assert(!_deck.isEmpty);
    _deck.drawCard(_playerHand);
    GameState nextState = _opponentHand.canAcquireCard()
        ? _stateMachine.opponentDrawState
        : _stateMachine.opponentTurnState;
    _stateMachine.transitionTo(nextState);
  }

  void triggerOpponentDraw() {
    assert(!_deck.isEmpty);
    _deck.drawCard(_opponentHand);
    GameState nextState = _playerHand.canAcquireCard()
        ? _stateMachine.playerDrawState
        : _stateMachine.playerTurnState;
    _stateMachine.transitionTo(nextState);
  }
}
