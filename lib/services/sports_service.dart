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
        print('Football API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Football Fetch Error: $e');
      return [];
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
        return results
            .map((e) => MatchScore.fromCricket(e))
            .toList();
      } else {
        print('Cricket API HTTP Error: ${response.statusCode}');
        print('Cricket API Body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Cricket Fetch Exception: $e');
      return [];
    }
  }
}