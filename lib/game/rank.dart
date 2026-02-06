enum Rank implements Comparable<Rank> {
  ace(value: 1, points: 11, order: 10),
  three(value: 3, points: 10, order: 9),
  king(value: 10, points: 4, order: 8),
  knight(value: 9, points: 3, order: 7),
  jack(value: 8, points: 2, order: 6),
  seven(value: 7, points: 0, order: 5),
  six(value: 6, points: 0, order: 4),
  five(value: 5, points: 0, order: 3),
  four(value: 4, points: 0, order: 2),
  two(value: 2, points: 0, order: 1),;
  
  final int value;
  final int points;
  final int order;

  const Rank({
    required this.value,
    required this.points,
    required this.order,
  });

  static int get minValue => ace.value;
  static int get maxValue => king.value;

  factory Rank.fromInt(int value) {
    return Rank.values.firstWhere((rank) => rank.value == value);
  }
  
  @override
  int compareTo(Rank other) {
    return order - other.order;
  }
}