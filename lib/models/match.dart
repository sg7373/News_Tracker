class MatchScore {
  final String teamA;
  final String teamB;
  final String score;
  final String sport; // 'football' or 'cricket'
  final String status;
  final String matchType;
  final String date;
  final String venue;
  final bool isLive;

  MatchScore({
    required this.teamA,
    required this.teamB,
    required this.score,
    required this.sport,
    this.status = 'Live',
    this.matchType = '',
    this.date = '',
    this.venue = '',
    this.isLive = false,
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
      matchType: fixture['league']?['name'] ?? 'League',
      date: fixture['date'] != null ? DateTime.parse(fixture['date']).toLocal().toString().split(' ')[0] : '',
      venue: fixture['venue']?['name'] ?? '',
      isLive: statusMap['short'] == '1H' || statusMap['short'] == '2H' || statusMap['short'] == 'HT' || statusMap['short'] == 'ET' || statusMap['short'] == 'P',
    );
  }

  factory MatchScore.fromCricket(Map<String, dynamic> json) {
    // CricAPI v1 returns teams as a List of strings e.g. ["India", "Australia"]
    final List teams = json['teams'] ?? [];
    final String teamA = teams.isNotEmpty ? teams[0].toString() : (json['name']?.toString().split(' vs ').first ?? 'Team A');
    final String teamB = teams.length > 1 ? teams[1].toString() : (json['name']?.toString().split(' vs ').last ?? 'Team B');

    // CricAPI v1 returns score as a List of objects: [{r, w, o, inning}, ...]
    final List scoreList = json['score'] ?? [];
    String scoreStr = '-';
    if (scoreList.isNotEmpty) {
      scoreStr = scoreList.map((s) {
        final inning = s['inning']?.toString() ?? '';
        final r = s['r']?.toString() ?? '0';
        final w = s['w']?.toString() ?? '0';
        final o = s['o']?.toString() ?? '0';
        return '$inning: $r/$w ($o ov)';
      }).join('  |  ');
    }

    final bool isLive = json['matchStarted'] == true && json['matchEnded'] != true;
    final String dateStr = json['date'] ?? json['dateTimeGMT'] ?? '';
    final String titleStr = json['name'] ?? '';

    return MatchScore(
      teamA: teamA,
      teamB: teamB,
      score: scoreStr,
      sport: 'cricket',
      status: json['status'] ?? (isLive ? 'Live' : (json['matchEnded'] == true ? 'Finished' : 'Upcoming')),
      matchType: json['matchType']?.toString().toUpperCase() ?? 'T20',
      date: dateStr.isNotEmpty && dateStr.contains('T') ? DateTime.tryParse(dateStr)?.toLocal().toString().substring(0, 16) ?? dateStr : dateStr,
      venue: json['venue'] ?? titleStr.split(',').last.trim(),
      isLive: isLive,
    );
  }
}