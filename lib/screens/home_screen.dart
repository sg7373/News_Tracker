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
      appBar: AppBar(
        title: const Text('Inshorts Clone'),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => newsProvider.fetchNews(category: newsProvider.currentCategory),
        child: Stack(
          children: [
            if (!newsProvider.isLoading && newsProvider.error == null)
              PageView.builder(
                scrollDirection: Axis.vertical,
                itemCount: newsProvider.articles.length,
                itemBuilder: (context, index) {
                  final article = newsProvider.articles[index];
                  return NewsCard(article: article);
                },
              )
            else if (newsProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (newsProvider.error != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${newsProvider.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => newsProvider.fetchNews(category: newsProvider.currentCategory),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else
              const Center(child: Text('No news available')),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = newsProvider.currentCategory == cat['code'];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(cat['name']!),
                  selected: isSelected,
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
      ),
    );
  }
}