import 'package:briscola/game/briscola_game.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  final World _world;
  final void Function() _onDispose;

  const GameScreen(this._world, this._onDispose, {super.key});

  @override
  State<StatefulWidget> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final BriscolaGame _game;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game')),
      body: Stack(
        fit: StackFit.expand,
        children: [GameWidget(game: _game)],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _game = BriscolaGame(widget._world);
  }

  @override
  void dispose() {
    widget._onDispose();
    super.dispose();
  }
}
