import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';
import '../constants/api_keys.dart';

class NewsService {
  // 🔹 Use the central API key from constants/api_keys.dart for consistency and security
  final String _apiKey = newsApiKey;

  // =====================================================
  // FETCH TRENDING NEWS
  // =====================================================
  Future<List<Article>> fetchTrending({int page = 1}) async {
    // 🔹 Massive list of 25+ major global and local sources to maximize "Unlimited" results for the project.
    // This provides Today's (Feb 28) most diverse and comprehensive real-time feed.
    final sources = [
      'google-news', 'bbc-news', 'the-hindu', 'the-times-of-india', 
      'reuters', 'associated-press', 'abc-news', 'cnn', 'fox-news', 'al-jazeera-english',
      'the-washington-post', 'time', 'usa-today', 'the-verge', 'techcrunch', 
      'wired', 'business-insider', 'bloomberg', 'cnbc', 'fortune', 'independent',
      'the-wall-street-journal', 'guardian', 'financial-times', 'news-com-au'
    ].join(',');
    
    // 🔹 Increased pageSize to 50 for a "Project-Ready" bulky first load
    final url = Uri.parse(
      "https://newsapi.org/v2/top-headlines?sources=$sources&pageSize=50&page=$page&apiKey=$_apiKey",
    );

    try {
      final response = await http.get(url);

      print("Trending STATUS: ${response.statusCode} Page: $page");

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));

      if (data["status"] != "ok") {
        throw Exception(data["message"] ?? "Failed to fetch trending news");
      }

      List articles = data["articles"] ?? [];

      return articles
          .where((json) =>
              json["title"] != null &&
              json["title"] != "[Removed]" &&
              json["url"] != null)
          .map<Article>((json) => Article.fromJson(json))
          .toList();
    } catch (e) {
      print("Trending ERROR: $e");
      rethrow;
    }
  }

  // =====================================================
  // FETCH TOP HEADLINES BY CATEGORY
  // =====================================================
  Future<List<Article>> fetchTopHeadlines({required String category, int page = 1}) async {
    // 'trending' is not a valid predefined NewsAPI category. Use 'general' instead.
    if (category.toLowerCase() == 'trending') {
      return fetchTrending(page: page);
    }

    // 🔹 Using language=en and category logic for verified professional news sections.
    final url = Uri.parse(
      "https://newsapi.org/v2/top-headlines?language=en&category=${Uri.encodeComponent(category)}&pageSize=50&page=$page&apiKey=$_apiKey",
    );

    try {
      final response = await http.get(url);

      print("Category STATUS: ${response.statusCode} Page: $page");

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));

      if (data["status"] != "ok") {
        throw Exception(data["message"] ?? "Failed to load category news");
      }

      List articles = data["articles"] ?? [];

      return articles
          .where((json) =>
              json["title"] != null &&
              json["title"] != "[Removed]" &&
              json["url"] != null)
          .map<Article>((json) => Article.fromJson(json))
          .toList();
    } catch (e) {
      print("Category ERROR: $e");
      rethrow;
    }
  }

  // =====================================================
  // SEARCH NEWS
  // =====================================================
  Future<List<Article>> searchNews({required String query, int page = 1}) async {
    final encodedQuery = Uri.encodeComponent(query);

    // 🔹 Still 50 results per search to give that "Unlimited" look
    final url = Uri.parse(
      "https://newsapi.org/v2/everything?q=$encodedQuery&language=en&sortBy=publishedAt&pageSize=50&page=$page&apiKey=$_apiKey",
    );

    try {
      final response = await http.get(url);

      print("Search STATUS: ${response.statusCode} Page: $page");

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));

      if (data["status"] != "ok") {
        throw Exception(data["message"] ?? "Search failed");
      }

      List articles = data["articles"] ?? [];

      return articles
          .where((json) =>
              json["title"] != null &&
              json["title"] != "[Removed]" &&
              json["url"] != null)
          .map<Article>((json) => Article.fromJson(json))
          .toList();
    } catch (e) {
      print("Search ERROR: $e");
      rethrow;
    }
  }
}
