import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';
import '../models/match.dart'; // Make sure this file exists

class NewsService {
  final String _apiKey = 'b28b37248a254603a20b0633d600fd95';
  final String _baseUrl = 'https://api.worldnewsapi.com';

  // 1. Fetch Top Headlines (News)
  Future<List<Article>> fetchTopHeadlines({required String category}) async {
    final url = '$_baseUrl/top-news?source-country=us&language=en&api-key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List? topNewsClusters = data['top_news'];
        
        if (topNewsClusters == null) return [];

        List<Article> articles = [];
        for (var cluster in topNewsClusters) {
          if (cluster['news'] != null && cluster['news'].isNotEmpty) {
            // Mapping World News API data to your Article model
            articles.add(Article.fromJson(cluster['news'][0]));
          }
        }
        return articles;
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('News Fetch Error: $e');
    }
  }

  // 2. Search News
  Future<List<Article>> searchNews({required String query}) async {
    final url = '$_baseUrl/search-news?text=$query&api-key=$_apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List? newsJson = data['news'];
        if (newsJson == null) return [];
        return newsJson.map((json) => Article.fromJson(json)).toList();
      } else {
        throw Exception('Search failed');
      }
    } catch (e) {
      throw Exception('Search error: $e');
    }
  }

  // 3. Fetch Live Scores (Football/Cricket)
  // Note: Since World News API is mainly for text news, we use a 
  // sports-specific API here. Ensure your MatchScore model matches this.
  Future<List<MatchScore>> fetchLiveScores() async {
    // Replace this with your actual Sports API URL (e.g., CricAPI or Sportmonks)
    final String sportsUrl = 'https://api.your-sports-api.com/v1/live?api-key=YOUR_SPORTS_KEY';

    try {
      final response = await http.get(Uri.parse(sportsUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Usually, sports APIs return a list under 'data', 'matches', or 'livescore'
        final List? matchesJson = data['matches'] ?? data['data'];
        
        if (matchesJson == null) return [];
        
        return matchesJson.map((json) => MatchScore.fromJson(json)).toList();
      } else {
        print('Sports API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Sports Fetch Error: $e');
      return []; // Return empty list so UI doesn't crash
    }
  }
}