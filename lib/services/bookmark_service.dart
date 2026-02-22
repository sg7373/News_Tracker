import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkService {
  static const String _key = "bookmarks";

  static Future<List<Map<String, dynamic>>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? data = prefs.getStringList(_key);
    
    if (data == null) return [];

    List<Map<String, dynamic>> bookmarks = [];
    for (var item in data) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          bookmarks.add(decoded);
        }
      } catch (e) {
        // If one item is broken, skip it so the list length remains valid
        continue; 
      }
    }
    return bookmarks;
  }

  static Future<void> addBookmark(Map<String, dynamic> article) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    
    final title = article["title"];
    if (title == null) return;

    // Check for duplicates safely
    bool exists = false;
    for (var item in data) {
      try {
        if (jsonDecode(item)["title"] == title) {
          exists = true;
          break;
        }
      } catch (_) {}
    }

    if (!exists) {
      data.add(jsonEncode(article));
      await prefs.setStringList(_key, data);
    }
  }

  static Future<void> removeBookmark(String title) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];

    data.removeWhere((item) {
      try {
        return jsonDecode(item)["title"] == title;
      } catch (_) {
        return false;
      }
    });

    await prefs.setStringList(_key, data);
  }

  static Future<bool> isBookmarked(String title) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((element) => element["title"] == title);
  }
}