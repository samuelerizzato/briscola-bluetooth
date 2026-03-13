import 'dart:async';
import 'dart:ui';
import 'package:briscola/game/components/playing_surface.dart';
import 'package:briscola/game/states/game_state.dart';
import 'package:briscola/game/states/state_machine.dart';
import 'package:flutter/material.dart' as material;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';

import 'package:briscola/game/briscola_world.dart';
import 'package:briscola/game/card_holder.dart';
import 'package:briscola/game/components/card.dart';

class TricksPile extends PositionComponent
    with TapCallbacks
    implements CardHolder {
  final List<Card> _cards = [];
  late final TextComponent scoreText;
  bool isActive = false;
  final Paint _activeBackgroundPaint;
  final PlayerType _type;

  TricksPile(Color activeColor, this._type)
    : _activeBackgroundPaint = Paint()
        ..color = activeColor.withAlpha(0x88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0);

  static final RRect pileRRect = RRect.fromRectAndRadius(
    BriscolaWorld.cardSize.toRect(),
    const Radius.circular(BriscolaWorld.cardRadius),
  );

  static final RRect activePileRRect = RRect.fromRectAndRadius(
    BriscolaWorld.cardSize.toRect(),
    const Radius.circular(BriscolaWorld.cardRadius),
  ).inflate(5.0);

  static final Paint backgroundPaint = Paint()
    ..color = const Color(0x88ffffff)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10;

  @override
  void acquireCard(Card card) {
    card.position = position;
    card.priority = _cards.length + 1;
    card.flip();
    _cards.add(card);
    scoreText.text = countPoints().toString();
  }

  int countPoints() => _cards
      .map((card) => card.rank.points)
      .reduce((value, points) => value + points);

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    final pileCenter = Vector2(
      BriscolaWorld.cardWidth / 2.0,
      BriscolaWorld.cardHeight / 2.0,
    );

    scoreText = TextComponent(
      text: 0.toString(),
      textRenderer: TextPaint(
        style: material.TextStyle(
          fontSize: 30.0,
          fontFamily: 'LilitaOne',
          color: material.Colors.white,
        ),
      ),
      position: pileCenter,
      anchor: Anchor.center,
    );

    add(
      CircleComponent(
        radius: 30.0,
        position: pileCenter,
        anchor: Anchor.center,
        paint: Paint()..color = _activeBackgroundPaint.color.withAlpha(0xff),
      ),
    );
    add(scoreText);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(pileRRect, backgroundPaint);
    if (isActive) {
      canvas.drawRRect(activePileRRect, _activeBackgroundPaint);
    }
  }

  @override
  Card removeCard(Card card) {
    throw StateError('Cannot remove card from tricks pile');
  }

  void onGameStateChanged(GameState state) {
    isActive =
        _type == state.currentHand.type &&
        (state.phase == GamePhase.play || state.phase == GamePhase.draw);
  }
}
