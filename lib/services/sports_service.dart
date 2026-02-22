import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match.dart';
import '../constants/api_keys.dart';

class SportsService {
  Future<List<Match>> fetchFootballMatches() async {
    final url = Uri.parse('https://api-football.com/matches?apiKey=$footballApiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> matchesJson = data['matches'] ?? [];
      return matchesJson.map((e) => Match.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch football matches');
    }
  }

  Future<List<Match>> fetchCricketMatches() async {
    final url = Uri.parse('https://cricapi.com/api/matches?apikey=$cricketApiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> matchesJson = data['matches'] ?? [];
      return matchesJson.map((e) => Match.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch cricket matches');
    }
  }
}