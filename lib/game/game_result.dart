class GameResult {
  final bool resigned;
  final int? points;
  final int? opponentPoints;
  const GameResult(this.resigned, [this.points, this.opponentPoints]);
}