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
  bool _isMockMode = false;

  List<Article> get articles => _articles;
  String get currentCategory => _currentCategory;
  bool get isLoading => _isLoading;
  bool get isMoreLoading => _isMoreLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get isMockMode => _isMockMode;

  final NewsService _newsService = NewsService();

  // Fetch news by category (initial page)
  Future<void> fetchNews({required String category}) async {
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    _hasMore = true;
    _currentSearchQuery = null;
    _isMockMode = false;
    
    // 🔹 Use microtask to avoid "setState during build" errors on startup
    Future.microtask(() => notifyListeners());

    try {
      _articles = await _newsService.fetchTopHeadlines(category: category, page: 1);
      _currentCategory = category;
      if (_articles.isEmpty) _hasMore = false;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('429') || errorStr.contains('rate') || errorStr.contains('limit')) {
        _isMockMode = true;
        _articles = _getMockArticles();
        _error = "API quota exhausted (Error 429). Switched to premium mock data for demonstration.";
      } else {
        _error = e.toString();
        _articles = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more articles (pagination)
  Future<void> loadMore() async {
    if (_isMoreLoading || !_hasMore || _isMockMode) return;

    if (_currentPage >= 2) {
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
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('429') || errorStr.contains('rate') || errorStr.contains('limit')) {
         _hasMore = false;
         _isMockMode = true;
      }
      print("Load More Error: $e");
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
    _isMockMode = false;
    
    // 🔹 Defer notification to avoid "setState during build" errors
    Future.microtask(() => notifyListeners());

    try {
      final result = await _newsService.searchNews(query: query, page: 1);
      _articles = result;
      if (_articles.isEmpty) _hasMore = false;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('429') || errorStr.contains('rate') || errorStr.contains('limit')) {
        _isMockMode = true;
        _articles = _getMockArticles();
        _error = "Search limit reached. Showing featured results.";
      } else {
        _error = e.toString();
        _articles = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Article> _getMockArticles() {
    return [
      Article(
        title: "Apple Unveils Revolutionary 'AirGlass' Augmented Reality Spectacles",
        description: "In a surprise keynote, Tim Cook showcased the future of wearable computing with AirGlass, a sleek pair of AR specs that integrate seamlessly with the Apple ecosystem.",
        url: "https://apple.com",
        urlToImage: "https://images.unsplash.com/photo-1593305841991-05c297ba4575?q=80&w=1200&auto=format&fit=crop",
        publishedAt: DateTime.now(),
        sourceName: "Apple Newsroom",
      ),
      Article(
        title: "Global Markets Rally as Inflation Drops to Record Lows",
        description: "Stock exchanges from New York to Tokyo saw massive gains today as new economic data suggests a perfect 'soft landing' for the global economy in 2026.",
        url: "https://bloomberg.com",
        urlToImage: "https://images.unsplash.com/photo-1611974714400-9838380e922e?q=80&w=1200&auto=format&fit=crop",
        publishedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        sourceName: "Bloomberg Finance",
      ),
      Article(
        title: "First Sustainable Lunar Colony Welcomes Earth-Origin Citizens",
        description: "The Artemis Base Camp has officially transitioned from a research station to a permanent human settlement, marking a new era for humanity's presence in space.",
        url: "https://nasa.gov",
        urlToImage: "https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?q=80&w=1200&auto=format&fit=crop",
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        sourceName: "NASA News",
      ),
      Article(
        title: "India Dominates World Cricket Championship in Final Over Thriller",
        description: "A spectacular performance by the middle order guided India to a historic victory against Australia in a match that will be remembered for decades.",
        url: "https://espncricinfo.com",
        urlToImage: "https://images.unsplash.com/photo-1531415074968-036ba1b575da?q=80&w=1200&auto=format&fit=crop",
        publishedAt: DateTime.now().subtract(const Duration(hours: 4)),
        sourceName: "ESPNCricinfo",
      ),
      Article(
        title: "Breakthrough in Fusion Energy: Clean Power for Every Home",
        description: "Scientists at the ITER project have successfully maintained a stable plasma for 48 hours, proving that unlimited clean energy is now within our reach.",
        url: "https://sciencedaily.com",
        urlToImage: "https://images.unsplash.com/photo-1510127034890-ba27508e9f1c?q=80&w=1200&auto=format&fit=crop",
        publishedAt: DateTime.now().subtract(const Duration(hours: 6)),
        sourceName: "Science Daily",
      ),
      Article(
        title: "Electric Formula 1: The Future of High-Speed Racing",
        description: "Formula 1 announces its full transition to hydrogen-electric power units for the 2030 season, promising faster speeds and zero emissions.",
        url: "https://formula1.com",
        urlToImage: "https://images.unsplash.com/photo-1547394765-185e1e68f34e?q=80&w=1200&auto=format&fit=crop",
        publishedAt: DateTime.now().subtract(const Duration(hours: 9)),
        sourceName: "Motorsport Total",
      ),
      Article(
        title: "Smart Cities: New Delhi Implements AI-Driven Traffic Grid",
        description: "Total commute times in the capital have decreased by 40% thanks to a new neural network that manages traffic patterns in real-time.",
        url: "https://hindustantimes.com",
        urlToImage: "https://images.unsplash.com/photo-1517420704212-680076ad06b5?q=80&w=1200&auto=format&fit=crop",
        publishedAt: DateTime.now().subtract(const Duration(hours: 12)),
        sourceName: "Hindustan Times",
      ),
    ];
  }
}