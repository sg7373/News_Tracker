import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match.dart';
import '../constants/api_keys.dart';

class SportsService {
  // ── Football: api-football v3 via RapidAPI ──────────────────────────────
  Future<List<MatchScore>> fetchFootballMatches() async {
    final url = Uri.parse('https://v3.football.api-sports.io/fixtures?live=all');

    try {
      final response = await http.get(url, headers: {
        'X-RapidAPI-Key': footballApiKey,
        'X-RapidAPI-Host': 'v3.football.api-sports.io',
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
    final url = Uri.parse(
        'https://api.cricapi.com/v1/currentMatches?apikey=$cricketApiKey&offset=0');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // CricAPI v1 wraps results in "data" key
        // status field tells if the request was successful
        if (data['status'] != 'success') {
          print('Cricket API returned non-success status: ${data['status']}');
          print('Cricket API message: ${data['message'] ?? 'unknown error'}');
          return [];
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
        score: "0 - 0",
        status: "HT",
        isLive: true,
        date: "Today",
        venue: "Emirates Stadium",
        sport: "Football",
        matchType: "Premier League",
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
        score: "342/5 vs 120/3",
        status: "India won by 120 runs",
        isLive: false,
        date: "Finished",
        venue: "Narendra Modi Stadium",
        sport: "Cricket",
        matchType: "ODI World Cup",
      ),
      MatchScore(
        teamA: "Australia",
        teamB: "England",
        score: "210/4 vs 198/all out",
        status: "Match Live",
        isLive: true,
        date: "Today",
        venue: "Melbourne Cricket Ground",
        sport: "Cricket",
        matchType: "T20I",
      ),
    ];
  }
}