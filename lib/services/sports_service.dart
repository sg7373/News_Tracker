import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match.dart';
import '../constants/api_keys.dart';

class SportsService {
  // ── Football: api-football v3 via API-Sports ───────────────────────────
  Future<List<MatchScore>> fetchFootballMatches() async {
    final url = Uri.parse('https://v3.football.api-sports.io/fixtures?live=all');

    try {
      final response = await http.get(url, headers: {
        'x-apisports-key': footballApiKey,
        'x-rapidapi-key': footballApiKey, // Fallback for some users
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle API-Sports errors (they often return 200 even on account errors)
        if (data['errors'] != null && data['errors'] is Map && (data['errors'] as Map).isNotEmpty) {
          final errorMsg = (data['errors'] as Map).values.first.toString();
          throw Exception("Football API: $errorMsg");
        }
        
        final List results = data['response'] ?? [];
        return results.map((e) => MatchScore.fromFootball(e)).toList();
      } else {
        throw Exception("Football API HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print('Football Fetch Error: $e');
      rethrow;
    }
  }

  // ── Cricket: cricapi v1 ─────────────────────────────────────────────────
  Future<List<MatchScore>> fetchCricketMatches() async {
    final url = Uri.parse(
        'https://api.cricapi.com/v1/currentMatches?apikey=$cricketApiKey&offset=0');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // CricAPI v1 wraps results in "data" key
        if (data['status'] != 'success') {
          final msg = data['reason'] ?? data['message'] ?? 'Unknown Cricket error';
          throw Exception("Cricket API: $msg");
        }

        final List results = data['data'] ?? [];
        return results.map((e) => MatchScore.fromCricket(e)).toList();
      } else {
        throw Exception("Cricket API Error: ${response.statusCode}");
      }
    } catch (e) {
      print('Cricket Fetch Exception: $e');
      rethrow;
    }
  }

  // ── MOCK DATA FOR DEMO ──────────────────────────────────────────────
  List<MatchScore> getMockFootballMatches() {
    return [
      MatchScore(
        teamA: "Real Madrid",
        teamB: "Barcelona",
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
        score: "1 - 1",
        status: "HT",
        isLive: true,
        date: "Today",
        venue: "Emirates Stadium",
        sport: "Football",
        matchType: "Premier League",
      ),
      MatchScore(
        teamA: "PSG",
        teamB: "Marseille",
        score: "0 - 0",
        status: "Coming Up",
        isLive: false,
        date: "21:00",
        venue: "Parc des Princes",
        sport: "Football",
        matchType: "Ligue 1",
      ),
      MatchScore(
        teamA: "Bayern Munich",
        teamB: "Dortmund",
        score: "3 - 0",
        status: "FT",
        isLive: false,
        date: "Yesterday",
        venue: "Allianz Arena",
        sport: "Football",
        matchType: "Bundesliga",
      ),
    ];
  }

  List<MatchScore> getMockCricketMatches() {
    return [
      MatchScore(
        teamA: "India",
        teamB: "Pakistan",
        score: "342/5 (50.0) vs 222/all out (44.3)",
        status: "India won by 120 runs",
        isLive: false,
        date: "Finished",
        venue: "Ahmedabad",
        sport: "Cricket",
        matchType: "ODI World Cup",
      ),
      MatchScore(
        teamA: "Australia",
        teamB: "England",
        score: "210/4 (18.2) vs 198/6 (20.0)",
        status: "Australia needs 10 runs in 10 balls",
        isLive: true,
        date: "Today",
        venue: "Melbourne",
        sport: "Cricket",
        matchType: "T20I",
      ),
      MatchScore(
        teamA: "South Africa",
        teamB: "New Zealand",
        score: "125/2 (15.0)",
        status: "Rain Interruption",
        isLive: true,
        date: "Today",
        venue: "Cape Town",
        sport: "Cricket",
        matchType: "Test Match",
      ),
    ];
  }
}