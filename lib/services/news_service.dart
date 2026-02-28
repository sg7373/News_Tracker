import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class NewsService {
  final String apiKey = "YOUR-API_KEY";

  // =====================================================~
  // FETCH TRENDING NEWS
  // =====================================================
  Future<List<Article>> fetchTrending() async {
    final url = Uri.parse(
      "https://newsapi.org/v2/everything?q=india&language=en&sortBy=publishedAt&pageSize=20&apiKey=$apiKey",
    );

    try {
      final response = await http.get(url);

      print("Trending STATUS: ${response.statusCode}");
      print("Trending BODY: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);

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
  Future<List<Article>> fetchTopHeadlines({required String category}) async {
    final url = Uri.parse(
      "https://newsapi.org/v2/top-headlines?country=us&category=${Uri.encodeComponent(category)}&pageSize=20&apiKey=$apiKey",
    );

    try {
      final response = await http.get(url);

      print("Category STATUS: ${response.statusCode}");
      print("Category BODY: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);

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
  Future<List<Article>> searchNews({required String query}) async {
    final encodedQuery = Uri.encodeComponent(query);

    final url = Uri.parse(
      "https://newsapi.org/v2/everything?q=$encodedQuery&language=en&sortBy=publishedAt&pageSize=20&apiKey=$apiKey",
    );

    try {
      final response = await http.get(url);

      print("Search STATUS: ${response.statusCode}");
      print("Search BODY: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);

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
