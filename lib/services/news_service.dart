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
    // 🔹 Expanded list of 50+ major global and local sources for a massive "Unlimited" look
    final sources = [
      'bbc-news', 'the-hindu', 'the-times-of-india', 
      'reuters', 'associated-press', 'abc-news', 'cnn', 'fox-news', 'al-jazeera-english',
      'the-washington-post', 'time', 'usa-today', 'the-verge', 'techcrunch', 
      'wired', 'business-insider', 'bloomberg', 'cnbc', 'fortune', 'independent',
      'the-wall-street-journal', 'the-guardian-uk', 'financial-times', 'news-com-au',
      'daily-mail', 'the-telegraph', 'the-hill', 'politico', 'nbc-news', 'cbs-news',
      'msnbc', 'the-next-web', 'national-geographic', 'ign', 'entertainment-weekly',
      'buzzfeed', 'mtv-news-uk', 'the-huffington-post', 'vice-news', 'ars-technica',
      'mashable', 'engadget', 'techradar', 'next-big-future', 'crypto-coins-news',
      'australian-financial-review', 'financial-post', 'cbc-news', 'medical-news-today'
    ].take(50).join(',');
    
    // 🔹 Increased pageSize to 100 for a "Bulky" first load
    final url = Uri.parse(
      "https://newsapi.org/v2/top-headlines?sources=$sources&pageSize=20&page=$page&apiKey=$_apiKey",
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
      print("Trending RAW count: ${articles.length}");

      final filtered = _filterArticles(articles);
          
      print("Trending FILTERED count: ${filtered.length}");
      return filtered;
    } catch (e) {
      print("Trending ERROR: $e");
      rethrow;
    }
  }

  // =====================================================
  // FETCH TOP HEADLINES BY CATEGORY
  // =====================================================
  Future<List<Article>> fetchTopHeadlines({required String category, int page = 1}) async {
    if (category.toLowerCase() == 'trending') {
      return fetchTrending(page: page);
    }

    try {
      late http.Response response;
      
      // 🔹 Business uses /everything endpoint — much larger pool, enables proper multi-page loading
      if (category.toLowerCase() == 'business') {
        final url = Uri.parse(
          "https://newsapi.org/v2/everything?q=business+finance+economy+market+stock&language=en&sortBy=publishedAt&pageSize=20&page=$page&apiKey=$_apiKey",
        );
        response = await http.get(url);
      } else {
        final url = Uri.parse(
          "https://newsapi.org/v2/top-headlines?language=en&category=${Uri.encodeComponent(category)}&pageSize=20&page=$page&apiKey=$_apiKey",
        );
        response = await http.get(url);
      }

      print("Category STATUS: ${response.statusCode} Page: $page ($category)");

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
      if (data["status"] != "ok") {
        throw Exception(data["message"] ?? "Failed to load category news");
      }

      List articles = data["articles"] ?? [];
      final filtered = _filterArticles(articles);
      print("Category FILTERED count: ${filtered.length} ($category page $page)");
      return filtered;
    } catch (e) {
      print("Category ERROR: $e");
      rethrow;
    }
  }

  // 🔹 Modularized filter to avoid duplication and inconsistencies
  List<Article> _filterArticles(List articles) {
    return articles
        .where((json) =>
            json["title"] != null &&
            json["title"] != "[Removed]" &&
            json["url"] != null &&
            json["urlToImage"] != null &&
            json["urlToImage"].toString().isNotEmpty &&
            ((json["description"] != null && json["description"].toString().trim().isNotEmpty) || 
             (json["content"] != null && json["content"].toString().trim().isNotEmpty)))
        .map<Article>((json) => Article.fromJson(json))
        .toList();
  }

  // =====================================================
  // SEARCH NEWS
  // =====================================================
  Future<List<Article>> searchNews({required String query, int page = 1}) async {
    final encodedQuery = Uri.encodeComponent(query);

    // 🔹 100 results per search to give that "Unlimited" look
    final url = Uri.parse(
      "https://newsapi.org/v2/everything?q=$encodedQuery&language=en&sortBy=publishedAt&pageSize=20&page=$page&apiKey=$_apiKey",
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
      return _filterArticles(articles);
    } catch (e) {
      print("Search ERROR: $e");
      rethrow;
    }
  }
}
