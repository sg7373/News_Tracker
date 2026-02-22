import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class NewsService {
  final String apiKey = "d7b58ae4d4754df583e78e92879f7f94"; 

  // ===============================
  // FETCH TOP HEADLINES BY CATEGORY
  // ===============================
  Future<List<Article>> fetchTopHeadlines({required String category}) async {
    final url = Uri.parse(
      "https://newsapi.org/v2/top-headlines?country=us&category=$category&apiKey=$apiKey",
    );

    try {
      final response = await http.get(url);

      final data = jsonDecode(response.body);

      print("API Response: $data"); // 👈 Debug print

      if (response.statusCode == 200 && data["status"] == "ok") {
        List articles = data["articles"];

        // Remove null / invalid articles
        return articles
            .where((json) =>
                json["title"] != null &&
                json["title"] != "[Removed]" &&
                json["url"] != null)
            .map((json) => Article.fromJson(json))
            .toList();
      } else {
        throw Exception(data["message"] ?? "Failed to load news");
      }
    } catch (e) {
      throw Exception("Error fetching news: $e");
    }
  }

  // ===============================
  // SEARCH NEWS
  // ===============================
  Future<List<Article>> searchNews({required String query}) async {
    final url = Uri.parse(
      "https://newsapi.org/v2/everything?q=$query&sortBy=publishedAt&language=en&apiKey=$apiKey",
    );

    try {
      final response = await http.get(url);

      final data = jsonDecode(response.body);

      print("Search Response: $data"); // 👈 Debug print

      if (response.statusCode == 200 && data["status"] == "ok") {
        List articles = data["articles"];

        return articles
            .where((json) =>
                json["title"] != null &&
                json["title"] != "[Removed]" &&
                json["url"] != null)
            .map((json) => Article.fromJson(json))
            .toList();
      } else {
        throw Exception(data["message"] ?? "Search failed");
      }
    } catch (e) {
      throw Exception("Error searching news: $e");
    }
  }
}