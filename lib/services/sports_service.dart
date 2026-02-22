import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match.dart'; // Ensure this file now uses 'MatchScore'

class SportsService {
  // Football API Logic
  Future<List<MatchScore>> fetchFootballMatches() async {
    final url = Uri.parse('https://api-football.com/matches?apiKey=67f7e18c172fb1e3b55fce3610af88d4');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List matchesJson = data['matches'] ?? [];
        return matchesJson.map((e) => MatchScore.fromJson(e)).toList();
      } else {
        return []; // Return empty list instead of crashing
      }
    } catch (e) {
      print('Football Fetch Error: $e');
      return [];
    }
  }

  // Cricket API Logic
  Future<List<MatchScore>> fetchCricketMatches() async {
    final url = Uri.parse('https://cricapi.com/api/matches?apikey=5fe5d118-bffb-41de-8f66-31f820caa504');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List matchesJson = data['matches'] ?? [];
        return matchesJson.map((e) => MatchScore.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Cricket Fetch Error: $e');
      return [];
    }
  }
}