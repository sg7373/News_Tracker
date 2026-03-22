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
  final String teamALogo;
  final String teamBLogo;

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
    this.teamALogo = '',
    this.teamBLogo = '',
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
      teamALogo: teams['home']?['logo'] ?? '',
      teamBLogo: teams['away']?['logo'] ?? '',
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
    final String fullName = json['name']?.toString() ?? '';
    
    String teamA = 'Team A';
    String teamB = 'Team B';

    if (teams.isNotEmpty) {
      teamA = teams[0].toString();
      if (teams.length > 1) teamB = teams[1].toString();
    } else if (fullName.isNotEmpty) {
      // Handle "NZ vs SA" or "NZ v SA"
      final parts = fullName.contains(' vs ') ? fullName.split(' vs ') : fullName.split(' v ');
      if (parts.length >= 2) {
        teamA = parts[0].split(',').first.trim();
        teamB = parts[1].split(',').first.trim();
      } else {
        teamA = fullName;
      }
    }

    final List scoreList = json['score'] ?? [];
    String scoreA = '';
    String scoreB = '';

    if (scoreList.isNotEmpty) {
      for (var s in scoreList) {
        final inning = s['inning']?.toString() ?? '';
        final r = s['r']?.toString() ?? '0';
        final w = s['w']?.toString() ?? '0';
        final o = s['o']?.toString() ?? '0';
        final formattedScore = '$r/$w ($o)';
        
        if (teamA.isNotEmpty && inning.toLowerCase().contains(teamA.toLowerCase())) {
          scoreA = scoreA.isEmpty ? formattedScore : '$scoreA, $formattedScore';
        } else if (teamB.isNotEmpty && inning.toLowerCase().contains(teamB.toLowerCase())) {
          scoreB = scoreB.isEmpty ? formattedScore : '$scoreB, $formattedScore';
        } else {
          if (scoreA.isEmpty) {
            scoreA = formattedScore;
          } else {
            scoreB = scoreB.isEmpty ? formattedScore : '$scoreB, $formattedScore';
          }
        }
      }
    }

    String scoreStr = '${scoreA.isNotEmpty ? scoreA : '-'} vs ${scoreB.isNotEmpty ? scoreB : '-'}';

    // If scoreStr is still empty/placeholder, try extracting from status
    final String status = json['status'] ?? '';
    if ((scoreA.isEmpty && scoreB.isEmpty) || scoreStr.contains('- vs -')) {
      // Regex to find things like "SA 120/3" or "120/3 (15.2)"
      final scoreRegex = RegExp(r'(\d+/\d+(\s*\(\d+(\.\d+)?\))?)');
      final matches = scoreRegex.allMatches(status).toList();
      if (matches.isNotEmpty) {
        scoreStr = status; // Use the descriptive status as the score if we found score-like patterns
      }
    }

    final bool isLive = json['matchStarted'] == true && json['matchEnded'] != true;
    final String dateStr = json['date'] ?? json['dateTimeGMT'] ?? '';
    final String titleStr = json['name'] ?? '';

    // Extract logos
    final List teamInfo = json['teamInfo'] ?? [];
    String logoA = '';
    String logoB = '';

    for (var info in teamInfo) {
      final name = info['name']?.toString() ?? '';
      if (name.toLowerCase() == teamA.toLowerCase()) {
        logoA = info['img'] ?? '';
      } else if (name.toLowerCase() == teamB.toLowerCase()) {
        logoB = info['img'] ?? '';
      }
    }
    // Fallback if name matching fails, just take first two
    if (logoA.isEmpty && teamInfo.isNotEmpty) logoA = teamInfo[0]['img'] ?? '';
    if (logoB.isEmpty && teamInfo.length > 1) logoB = teamInfo[1]['img'] ?? '';

    return MatchScore(
      teamA: teamA,
      teamB: teamB,
      teamALogo: logoA,
      teamBLogo: logoB,
      score: scoreStr,
      sport: 'cricket',
      status: json['status'] ?? (isLive ? 'Live' : (json['matchEnded'] == true ? 'Finished' : 'Upcoming')),
      matchType: json['matchType']?.toString().toUpperCase() ?? 'T20',
      date: (dateStr.isNotEmpty && dateStr.contains('T')) 
          ? (DateTime.tryParse(dateStr)?.toLocal().toString().length ?? 0) >= 16 
              ? DateTime.tryParse(dateStr)!.toLocal().toString().substring(0, 16) 
              : dateStr 
          : dateStr,
      venue: json['venue'] ?? titleStr.split(',').last.trim(),
      isLive: isLive,
    );
  }
}