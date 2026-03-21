import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../widgets/news_card.dart';
import '../services/update_service.dart';
import 'live_score.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'bookmarks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Timer? _timer; // 🔹 Timer for auto-refresh

  final List<Map<String, String>> categories = const [
    {'name': 'Trending', 'code': 'trending'},
    {'name': 'Business', 'code': 'business'},
    {'name': 'Technology', 'code': 'technology'},
    {'name': 'Sports', 'code': 'sports'},
    {'name': 'Entertainment', 'code': 'entertainment'},
    {'name': 'Health', 'code': 'health'},
    {'name': 'Science', 'code': 'science'},
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);

    // 🔹 Fetch news only if the list is currently empty to avoid duplicate requests
    if (newsProvider.articles.isEmpty) {
      newsProvider.fetchNews(category: newsProvider.currentCategory);
    }

    // 🔹 Auto-refresh current category news every 15 minutes (to stay within NewsAPI Free Tier limits)
    _timer = Timer.periodic(const Duration(minutes: 15), (timer) {
      newsProvider.fetchNews(category: newsProvider.currentCategory);
    });

    // 🔹 Check for app updates on launch (mobile only)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate(context);
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 🔹 Cancel the timer when screen closes
    super.dispose();
  }

  Widget _newsFeed(NewsProvider newsProvider) {
    return Column(
      children: [
        /// 🔹 CATEGORY BAR
        Container(
          height: 50,
          color: Colors.white,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = newsProvider.currentCategory == cat['code'];

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
                      // 🔹 Change category and fetch only that category news
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
            onRefresh: () =>
                newsProvider.fetchNews(category: newsProvider.currentCategory),
            child: Builder(
              builder: (_) {
                if (newsProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 🔥 HANDLE ERRORS (Show banner if mock mode, otherwise show full screen)
                if (newsProvider.error != null && !newsProvider.isMockMode) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('Error: ${newsProvider.error}',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => newsProvider.fetchNews(
                              category: newsProvider.currentCategory),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (newsProvider.articles.isEmpty) {
                  return const Center(child: Text('No news available'));
                }

                /// 🔥 SHOW LIST (With optional Mock Banner)
                return Column(
                  children: [
                    if (newsProvider.isMockMode)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        color: Colors.orange.shade50,
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 20, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                newsProvider.error ?? 'API Limit Reached. Showing Mock Data.',
                                style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
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
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = Provider.of<NewsProvider>(context);

    /// 🔹 SCREENS FOR BOTTOM NAVIGATION
    final List<Widget> screens = [
      _newsFeed(newsProvider),   // News Feed
      const LiveScoreScreen(),   // Live Scores
      const BookmarksScreen(),   // Bookmarks
    ];

    return Scaffold(
      backgroundColor: Colors.grey[200],

      /// 🔹 MODERN APP BAR
      appBar: AppBar(
        title: const Text(
          'News Tracker',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
        ],
      ),

      /// 🔹 BODY (SWITCHES BASED ON BOTTOM NAVIGATION)
      body: screens[_selectedIndex],

      /// 🔹 BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.red,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'News'),
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer), label: 'Live Score'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmark), label: 'Bookmarks'),
        ],
      ),
    );
  }
}