import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class NewsService {
  final String apiKey = "YOUR-API_KEY";

  // =====================================================
  // FETCH TRENDING NEWS
  // =====================================================
  Future<List<Article>> fetchTrending({int page = 1}) async {
    // Using top-headlines with specific sources gets us the newest Today's news.
    // The /everything endpoint is restricted to a 24-hour delay on free plans.
    final sources = [
      'google-news', 'bbc-news', 'the-hindu', 'the-times-of-india', 
      'reuters', 'associated-press', 'abc-news', 'cnn', 'fox-news', 'al-jazeera-english'
    ].join(',');
    
    final url = Uri.parse(
      "https://newsapi.org/v2/top-headlines?sources=$sources&pageSize=20&page=$page&apiKey=$apiKey",
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
      return [];
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

    final url = Uri.parse(
      "https://newsapi.org/v2/top-headlines?language=en&category=${Uri.encodeComponent(category)}&pageSize=20&page=$page&apiKey=$apiKey",
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
      return [];
    }
  }

  // =====================================================
  // SEARCH NEWS
  // =====================================================
  Future<List<Article>> searchNews({required String query, int page = 1}) async {
    final encodedQuery = Uri.encodeComponent(query);

    final url = Uri.parse(
      "https://newsapi.org/v2/everything?q=$encodedQuery&language=en&sortBy=publishedAt&pageSize=20&page=$page&apiKey=$apiKey",
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
      return [];
    }
  }
}
