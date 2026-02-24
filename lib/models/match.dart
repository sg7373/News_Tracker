class MatchScore {
  final String teamA;
  final String teamB;
  final String score;
  final String sport; // 'football' or 'cricket'
  final String status;

  MatchScore({
    required this.teamA,
    required this.teamB,
    required this.score,
    required this.sport,
    this.status = 'Live',
  });

  factory MatchScore.fromFootball(Map<String, dynamic> json) {
    final teams = json['teams'] ?? {};
    final goals = json['goals'] ?? {};
    final fixture = json['fixture'] ?? {};
    final statusMap = fixture['status'] ?? {};

    final homeGoals = goals['home']?.toString() ?? '-';
    final awayGoals = goals['away']?.toString() ?? '-';

    return MatchScore(
      teamA: teams['home']?['name'] ?? 'Home Team',
      teamB: teams['away']?['name'] ?? 'Away Team',
      score: '$homeGoals - $awayGoals',
      sport: 'football',
      status: statusMap['long'] ?? 'Live',
    );
  }

  factory MatchScore.fromCricket(Map<String, dynamic> json) {
    return MatchScore(
      teamA: json['t1'] ?? json['team-1'] ?? 'Team A',
      teamB: json['t2'] ?? json['team-2'] ?? 'Team B',
      score: '${json['t1s'] ?? '-'} vs ${json['t2s'] ?? '-'}',
      sport: 'cricket',
      status: json['matchStarted'] == true ? 'Live' : 'Upcoming',
    );
  }
}