class Match {
  final String teamA;
  final String teamB;
  final String score;
  final String status;

  Match({required this.teamA, required this.teamB, required this.score, required this.status});

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      teamA: json['teamA'] ?? '',
      teamB: json['teamB'] ?? '',
      score: json['score'] ?? '',
      status: json['status'] ?? '',
    );
  }
}