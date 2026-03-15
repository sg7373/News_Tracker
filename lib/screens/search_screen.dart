import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/news_service.dart';
import '../widgets/news_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NewsService _newsService = NewsService();

  // ─── Local state — completely isolated from the home feed ───
  List<Article> _results = [];
  bool _isLoading = false;
  String? _error;
  String _activeQuery = '';
  int _page = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Strict keyword relevance filter ────────────────────────
  // Keeps only articles where the query appears in title OR description.
  List<Article> _filterByRelevance(List<Article> articles, String query) {
    final terms = query.toLowerCase().split(' ').where((t) => t.length > 1).toList();
    if (terms.isEmpty) return articles;

    return articles.where((a) {
      final text = '${a.title} ${a.description ?? ''}'.toLowerCase();
      // Article must contain at least ONE of the search terms
      return terms.any((term) => text.contains(term));
    }).toList();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _results = [];
      _activeQuery = query;
      _page = 1;
      _hasMore = false;
    });

    try {
      final raw = await _newsService.searchNews(query: query, page: 1);
      final filtered = _filterByRelevance(raw, query);
      setState(() {
        _results = filtered;
        _hasMore = filtered.length >= 15; // assume more pages if we got a full batch
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _page + 1;
      final raw = await _newsService.searchNews(query: _activeQuery, page: nextPage);
      final filtered = _filterByRelevance(raw, _activeQuery);

      // Deduplicate against existing results
      final existingUrls = _results.map((a) => a.url).toSet();
      final fresh = filtered.where((a) => !existingUrls.contains(a.url)).toList();

      setState(() {
        _page = nextPage;
        _results.addAll(fresh);
        _hasMore = fresh.isNotEmpty && _page < 5;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Search News',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ─── Search Bar ───────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search by topic, keyword or person…',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Colors.red),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ─── Results ──────────────────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Initial state — nothing searched yet
    if (_activeQuery.isEmpty) {
      return _buildEmptyState(
        icon: Icons.travel_explore,
        title: 'Search for anything',
        subtitle: "Type a keyword, topic, or person's name to find relevant news.",
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (_error != null) {
      return _buildEmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Something went wrong',
        subtitle: _error!,
        action: TextButton.icon(
          onPressed: _search,
          icon: const Icon(Icons.refresh, color: Colors.red),
          label: const Text('Retry', style: TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_results.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No results for "$_activeQuery"',
        subtitle: 'Try different keywords or check your spelling.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _results.length) {
          // Load More button / spinner
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Center(
              child: _isLoadingMore
                  ? const CircularProgressIndicator(color: Colors.red)
                  : SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: _loadMore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('Load More', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
            ),
          );
        }

        return NewsCard(article: _results[index]);
      },
    );
  }

  // ─── Reusable empty/error state ──────────────────────────────
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5),
            ),
            if (action != null) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    );
  }
}