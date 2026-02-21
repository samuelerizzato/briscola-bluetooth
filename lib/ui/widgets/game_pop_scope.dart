import 'package:briscola/game/game_result.dart';
import 'package:briscola/ui/screens/game_result_screen.dart';
import 'package:briscola/ui/widgets/dialogs.dart';
import 'package:flutter/material.dart';

class GamePopScope extends StatelessWidget {
  final Future<bool> Function() _onLeaveGame;
  final Widget child;

  const GamePopScope(this._onLeaveGame, {super.key, required this.child});

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (bool didPop, Object? result) async {
      if (didPop) return;

      final bool shouldPop =
          await Dialogs.showBackDialog(context, _onLeaveGame) ?? false;
      if (context.mounted && shouldPop) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const GameResultScreen(
              result: GameResult(GameOutcome.resigned),
            ),
          ),
        );
      }
    },
    child: child,
  );
}
