import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarkService {
  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Returns the current user, or null if not signed in.
  static User? get _currentUser => FirebaseAuth.instance.currentUser;

  /// Reference to the bookmarks sub-collection for the signed-in user.
  static CollectionReference<Map<String, dynamic>>? get _bookmarksRef {
    final uid = _currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bookmarks');
  }

  /// We use the article title (URL-encoded) as the document ID so we can
  /// cheaply check existence without a query.
  static String _docId(String title) =>
      Uri.encodeComponent(title).replaceAll('%', '_');

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Fetch all bookmarks for the signed-in user (one-time read).
  static Future<List<Map<String, dynamic>>> getBookmarks() async {
    final ref = _bookmarksRef;
    if (ref == null) return [];

    try {
      final snapshot = await ref.orderBy('savedAt', descending: true).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  /// A real-time stream of the user's bookmarks (for BookmarksScreen).
  static Stream<List<Map<String, dynamic>>> bookmarksStream() {
    final ref = _bookmarksRef;
    if (ref == null) return const Stream.empty();

    return ref
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  /// Add an article to Firestore bookmarks.
  static Future<void> addBookmark(Map<String, dynamic> article) async {
    final ref = _bookmarksRef;
    if (ref == null) return;

    final title = article['title'];
    if (title == null) return;

    await ref.doc(_docId(title.toString())).set({
      ...article,
      'savedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Remove an article from Firestore bookmarks.
  static Future<void> removeBookmark(String title) async {
    final ref = _bookmarksRef;
    if (ref == null) return;

    await ref.doc(_docId(title)).delete();
  }

  /// Check if an article is already bookmarked (single document read).
  static Future<bool> isBookmarked(String title) async {
    final ref = _bookmarksRef;
    if (ref == null) return false;

    try {
      final doc = await ref.doc(_docId(title)).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }
}