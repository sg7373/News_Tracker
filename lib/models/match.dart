class MatchScore {
  final String teamA;
  final String teamB;
  final String score;

  MatchScore({required this.teamA, required this.teamB, required this.score});

  factory MatchScore.fromJson(Map<String, dynamic> json) {
    return MatchScore(
      // Handles both Football and Cricket API JSON structures
      teamA: json['home_team'] ?? json['team-1'] ?? 'Team A',
      teamB: json['away_team'] ?? json['team-2'] ?? 'Team B',
      score: json['score'] ?? 'Live',
    );
  }
}