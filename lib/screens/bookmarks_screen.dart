import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/bookmark_service.dart';
import '../services/auth_service.dart';
import '../widgets/news_card.dart';
import 'login_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // If not logged in, show the login prompt
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
                'Sign in to save and sync your bookmarks across all your devices.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                ),
                child: const Text('Log In / Sign Up'),
              ),
            ],
          ),
        ),
      );
    }

    // Stream-based UI — automatically reflects Firestore changes in real-time
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: BookmarkService.bookmarksStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading bookmarks:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        final bookmarks = snapshot.data ?? [];

        if (bookmarks.isEmpty) {
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

        final articles = bookmarks
            .map((e) {
              try {
                return Article.fromJson(e);
              } catch (_) {
                return null;
              }
            })
            .whereType<Article>()
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: articles.length,
          itemBuilder: (context, index) =>
              NewsCard(article: articles[index]),
        );
      },
    );
  }
}
