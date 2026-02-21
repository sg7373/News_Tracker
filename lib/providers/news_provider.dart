import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/news_service.dart';

class NewsProvider with ChangeNotifier {
  List<Article> _articles = [];
  String _currentCategory = 'general';
  bool _isLoading = false;
  String? _error;

  List<Article> get articles => _articles;
  String get currentCategory => _currentCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final NewsService _newsService = NewsService();

  Future<void> fetchNews({required String category}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _articles = await _newsService.fetchTopHeadlines(category: category);
      _currentCategory = category;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _articles = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void changeCategory(String category) {
    if (category != _currentCategory) {
      fetchNews(category: category);
    }
  }
}