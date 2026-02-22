import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../widgets/news_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Map<String, String>> categories = const [
    {'name': 'General', 'code': 'general'},
    {'name': 'Business', 'code': 'business'},
    {'name': 'Technology', 'code': 'technology'},
    {'name': 'Sports', 'code': 'sports'},
    {'name': 'Entertainment', 'code': 'entertainment'},
    {'name': 'Health', 'code': 'health'},
    {'name': 'Science', 'code': 'science'},
  ];

  @override
  Widget build(BuildContext context) {
    final newsProvider = Provider.of<NewsProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[200],

      /// 🔥 MODERN APP BAR
      appBar: AppBar(
        title: const Text(
          'Inshorts Clone',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      body: Column(
        children: [

          /// 🔹 CATEGORY BAR (TOP LIKE INSHORTS)
          Container(
            height: 50,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected =
                    newsProvider.currentCategory == cat['code'];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat['name']!),
                    selected: isSelected,
                    selectedColor: Colors.red.shade100,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.red : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        newsProvider.changeCategory(cat['code']!);
                      }
                    },
                  ),
                );
              },
            ),
          ),

          /// 🔹 NEWS CONTENT
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => newsProvider.fetchNews(
                category: newsProvider.currentCategory,
              ),
              child: Builder(
                builder: (_) {
                  if (newsProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (newsProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${newsProvider.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => newsProvider.fetchNews(
                              category: newsProvider.currentCategory,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (newsProvider.articles.isEmpty) {
                    return const Center(
                      child: Text('No news available'),
                    );
                  }

                  /// 🔥 VERTICAL SWIPE LIKE REAL INSHORTS
                  return PageView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: newsProvider.articles.length,
                    itemBuilder: (context, index) {
                      final article = newsProvider.articles[index];
                      return NewsCard(article: article);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}