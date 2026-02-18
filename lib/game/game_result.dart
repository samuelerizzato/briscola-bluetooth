class GameResult {
  final GameOutcome outcome;
  final int? points;
  final int? opponentPoints;

  const GameResult(this.outcome, {this.points, this.opponentPoints});
}

enum GameOutcome { win, loss, draw, resigned, opponentResigned }
