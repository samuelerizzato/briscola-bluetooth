import 'package:briscola/game/game_result.dart';
import 'package:flutter/material.dart';

class GameResultScreen extends StatelessWidget {
  const GameResultScreen({super.key, required this.result});

  final GameResult result;

  @override
  Widget build(BuildContext context) {
    bool resign =
        result.outcome == GameOutcome.resigned ||
        result.outcome == GameOutcome.opponentResigned;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              getOutcomeMessage(result.outcome),
              style: TextStyle(fontSize: 50.0),
            ),
            Text(
              getMessage(result.outcome),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (!resign) buildScoreTable(context),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Continue'.toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildScoreTable(BuildContext context) {
    return Column(
      children: [
        Table(
          children: [
            TableRow(
              children: [
                Container(
                  padding: EdgeInsets.only(right: 10.0),
                  alignment: AlignmentGeometry.centerRight,
                  child: Text(
                    'Your score',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(left: 10.0),
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    '${result.points} points',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Container(
                  padding: EdgeInsets.only(right: 10.0),
                  alignment: AlignmentGeometry.centerRight,
                  child: Text(
                    'Opponent score',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(left: 10.0),
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    '${result.opponentPoints} points',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String getOutcomeMessage(GameOutcome outcome) => switch (outcome) {
    GameOutcome.win || GameOutcome.opponentResigned => 'You won',
    GameOutcome.loss || GameOutcome.resigned => 'You lost',
    GameOutcome.draw => 'Draw',
  };

  String getMessage(GameOutcome outcome) => switch (outcome) {
    GameOutcome.resigned => 'You resigned from the game',
    GameOutcome.opponentResigned => 'Opponent resigned',
    GameOutcome.win => 'You have more points than the opponent',
    GameOutcome.loss => 'You have less points than the opponent',
    GameOutcome.draw => 'You and the opponent have the same points',
  };
}
