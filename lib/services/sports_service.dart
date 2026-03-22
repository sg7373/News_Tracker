import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match.dart';
import '../constants/api_keys.dart';

class SportsService {
  // ── Football: api-football v3 via API-Sports ──────────────────────────────
  Future<List<MatchScore>> fetchFootballMatches() async {
    final url = Uri.parse('https://v3.football.api-sports.io/fixtures?live=all');

    try {
      final response = await http.get(url, headers: {
        'x-apisports-key': footballApiKey,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['response'] ?? [];
        return results.map((e) => MatchScore.fromFootball(e)).toList();
      } else {
        throw Exception("Football API Error: ${response.statusCode}");
      }
    } catch (e) {
      print('Football Fetch Error: $e');
      rethrow;
    }
  }

  // ── Cricket: cricapi v1 ─────────────────────────────────────────────────
  Future<List<MatchScore>> fetchCricketMatches() async {
    final baseUrl = 'https://api.cricapi.com/v1';
    final Set<String> matchIds = {};
    final List<MatchScore> matches = [];

    // Try currentMatches first (most live scores here)
    try {
      final currentMatchesUrl = Uri.parse('$baseUrl/currentMatches?apikey=$cricketApiKey&offset=0');
      final response = await http.get(currentMatchesUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List results = data['data'] ?? [];
          for (var e in results) {
            final id = e['id']?.toString() ?? '';
            if (id.isNotEmpty && !matchIds.contains(id)) {
              matches.add(MatchScore.fromCricket(e));
              matchIds.add(id);
            }
          }
        }
      }
    } catch (e) {
      print('CurrentMatches fetch failed: $e');
    }

    // Always fallback/supplement with matches endpoint to catch any we missed
    try {
      final matchesUrl = Uri.parse('$baseUrl/matches?apikey=$cricketApiKey&offset=0');
      final response = await http.get(matchesUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List results = data['data'] ?? [];
          for (var e in results) {
            final id = e['id']?.toString() ?? '';
            if (id.isNotEmpty && !matchIds.contains(id)) {
              matches.add(MatchScore.fromCricket(e));
              matchIds.add(id);
            }
          }
        }
      }
    } catch (e) {
      print('Matches fetch failed: $e');
    }

    return matches;
  }

  // ── MOCK DATA FOR DEMO ──────────────────────────────────────────────
  List<MatchScore> getMockFootballMatches() {
    return [
      MatchScore(
        teamA: "Real Madrid",
        teamB: "Barcelona",
        teamALogo: "https://media.api-sports.io/football/teams/541.png",
        teamBLogo: "https://media.api-sports.io/football/teams/529.png",
        score: "2 - 1",
        status: "85'",
        isLive: true,
        date: "Today",
        venue: "Santiago Bernabéu",
        sport: "Football",
        matchType: "La Liga",
      ),
      MatchScore(
        teamA: "Arsenal",
        teamB: "Man City",
        teamALogo: "https://media.api-sports.io/football/teams/42.png",
        teamBLogo: "https://media.api-sports.io/football/teams/50.png",
        score: "0 - 0",
        status: "HT",
        isLive: true,
        date: "Today",
        venue: "Emirates Stadium",
        sport: "Football",
        matchType: "Premier League",
      ),
    ];
  }

  List<MatchScore> getMockCricketMatches() {
    return [
      MatchScore(
        teamA: "New Zealand",
        teamB: "South Africa",
        teamALogo: "https://g.cricapi.com/iapi/5-637877075482814881.webp?w=48",
        teamBLogo: "https://g.cricapi.com/iapi/4-637877074932814881.webp?w=48",
        score: "Match Live",
        status: "SA 145/2 (15.2) | NZ yet to bat",
        isLive: true,
        date: "Today",
        venue: "Sky Stadium, Wellington",
        sport: "Cricket",
        matchType: "T20I",
      ),
      MatchScore(
        teamA: "India",
        teamB: "Australia",
        teamALogo: "https://g.cricapi.com/iapi/1-637877073281488126.webp?w=48",
        teamBLogo: "https://g.cricapi.com/iapi/2-637877073832814881.webp?w=48",
        score: "210/4 (20) vs 198/all out (19.4)",
        status: "India won by 12 runs",
        isLive: false,
        date: "Finished",
        venue: "Narendra Modi Stadium",
        sport: "Cricket",
        matchType: "T20I",
      ),
    ];
  }
}