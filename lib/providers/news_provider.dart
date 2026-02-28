import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/news_service.dart';

class NewsProvider with ChangeNotifier {
  List<Article> _articles = [];
  String _currentCategory = 'general';
  bool _isLoading = false;
  bool _isMoreLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _currentSearchQuery;

  List<Article> get articles => _articles;
  String get currentCategory => _currentCategory;
  bool get isLoading => _isLoading;
  bool get isMoreLoading => _isMoreLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  final NewsService _newsService = NewsService();

  // Fetch news by category (initial page)
  Future<void> fetchNews({required String category}) async {
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    _hasMore = true;
    _currentSearchQuery = null;
    notifyListeners();

    try {
      _articles = await _newsService.fetchTopHeadlines(category: category, page: 1);
      _currentCategory = category;
      if (_articles.length < 20) _hasMore = false;
    } catch (e) {
      _error = e.toString();
      _articles = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more articles (pagination)
  Future<void> loadMore() async {
    if (_isMoreLoading || !_hasMore) return;

    // Hard limit for NewsAPI Free tier is 100 results total
    if (_currentPage >= 5) {
      _hasMore = false;
      notifyListeners();
      return;
    }

    _isMoreLoading = true;
    notifyListeners();

    try {
      _currentPage++;
      List<Article> nextBatch;
      
      if (_currentSearchQuery != null) {
        nextBatch = await _newsService.searchNews(query: _currentSearchQuery!, page: _currentPage);
      } else {
        nextBatch = await _newsService.fetchTopHeadlines(category: _currentCategory, page: _currentPage);
      }

      if (nextBatch.isEmpty) {
        _hasMore = false;
      } else {
        _articles.addAll(nextBatch);
        if (nextBatch.length < 20) _hasMore = false;
      }
    } catch (e) {
      print("Load More Error: $e");
      _hasMore = false;
    } finally {
      _isMoreLoading = false;
      notifyListeners();
    }
  }

  // Change category
  void changeCategory(String category) {
    if (category != _currentCategory || _currentSearchQuery != null) {
      fetchNews(category: category);
    }
  }

  // Search news by query
  Future<void> searchNews(String query) async {
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    _hasMore = true;
    _currentSearchQuery = query;
    notifyListeners();

    try {
      final result = await _newsService.searchNews(query: query, page: 1);
      _articles = result;
      if (_articles.length < 20) _hasMore = false;
    } catch (e) {
      _error = e.toString();
      _articles = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}