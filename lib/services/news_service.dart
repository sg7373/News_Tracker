import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';
import '../constants/api_keys.dart';

class NewsService {
  static const String _baseUrl = 'https://newsapi.org/v2/top-headlines';
  static const String _country = 'us';

  Future<List<Article>> fetchTopHeadlines({String category = 'general'}) async {
    final url = Uri.parse('$_baseUrl?country=$_country&category=$category&apiKey=$newsApiKey');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> articlesJson = data['articles'] ?? [];
        return articlesJson.map((json) => Article.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching news: $e');
      throw Exception('Failed to fetch news: $e');
    }
  }
}