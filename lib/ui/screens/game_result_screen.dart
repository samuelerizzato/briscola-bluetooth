import 'package:briscola/game/game_result.dart';
import 'package:briscola/ui/screens/home_screen.dart';
import 'package:flutter/material.dart';

class GameResultScreen extends StatelessWidget {
  const GameResultScreen({super.key, required this.result});
  final GameResult result;

  @override
  Widget build(BuildContext context) {
    String message;
    if (result.points > result.opponentPoints) {
      message = 'You won';
    } else if (result.points < result.opponentPoints) {
      message = 'You lost';
    } else {
      message = "Draw";
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(message, style: Theme.of(context).textTheme.displayMedium),
            Column(
              children: [
                Table(
                  children: [
                    TableRow(
                      children: [
                        Container(
                          padding: EdgeInsets.only(right: 5.0),
                          alignment: AlignmentGeometry.centerRight,
                          child: Text(
                            'Your score',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Center(
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
                          padding: EdgeInsets.only(right: 5.0),
                          alignment: AlignmentGeometry.centerRight,
                          child: Text(
                            'Opponent score',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Center(
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
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: Text('Go back to start menu'.toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }
}
