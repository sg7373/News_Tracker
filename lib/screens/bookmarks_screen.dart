import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/bookmark_service.dart';
import '../services/auth_service.dart';
import '../widgets/news_card.dart';
import 'login_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Article> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (AuthService().currentUser != null) {
      _loadBookmarks();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBookmarks() async {
    final raw = await BookmarkService.getBookmarks();
    if (mounted) {
      setState(() {
        _bookmarks = raw.map((e) => Article.fromJson(e)).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AuthService().currentUser == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'Login Required',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'To save and sync your bookmarks across devices, please sign in to your account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Log In / Sign Up'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (_bookmarks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No bookmarks yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the bookmark icon on any article to save it.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _bookmarks.length,
      itemBuilder: (context, index) => NewsCard(article: _bookmarks[index]),
    );
  }
}
