import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../widgets/news_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _query;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final provider = Provider.of<NewsProvider>(context, listen: false);
    setState(() {
      _query = _searchController.text.trim();
    });
    provider.searchNews(_query!); // Make sure you have this function in NewsProvider
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = Provider.of<NewsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search News'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          /// 🔹 Search Input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'Enter keyword...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _search,
                  child: const Text('Search'),
                )
              ],
            ),
          ),

          /// 🔹 Search Results
          Expanded(
            child: Builder(
              builder: (_) {
                if (_query == null || _query!.isEmpty) {
                  return const Center(child: Text('Type a keyword to search news'));
                }

                if (newsProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (newsProvider.error != null) {
                  return Center(
                    child: Text('Error: ${newsProvider.error}'),
                  );
                }

                if (newsProvider.articles.isEmpty) {
                  return const Center(child: Text('No results found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: newsProvider.articles.length + (newsProvider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == newsProvider.articles.length) {
                      // 🔹 LOAD MORE BUTTON / SPINNER
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Center(
                          child: newsProvider.isMoreLoading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                  width: 200,
                                  child: ElevatedButton(
                                    onPressed: () => newsProvider.loadMore(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      elevation: 4,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    child: const Text('Load More', style: TextStyle(fontWeight: FontWeight.w500)),
                                  ),
                                ),
                        ),
                      );
                    }
                    
                    final article = newsProvider.articles[index];
                    return NewsCard(article: article);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}