import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  // ─── IMPORTANT: Replace this URL with YOUR own after pushing version.json to GitHub ───
  // Format: https://raw.githubusercontent.com/<YOUR_GITHUB_USERNAME>/<REPO_NAME>/main/version.json
  static const String _versionFileUrl =
      'https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/news_tracker/main/version.json';

  /// Compare two version strings like "1.2.3"
  static bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length; i++) {
        if (i >= currentParts.length) return true;
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Call this on app open in HomeScreen.initState
  static Future<void> checkForUpdate(BuildContext context) async {
    // Skip update check on web
    if (kIsWeb) return;

    try {
      final response = await http
          .get(Uri.parse(_versionFileUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      final String latestVersion = data['version'];
      final String apkUrl = data['apk_url'];
      final String releaseNotes = data['release_notes'] ?? 'Bug fixes and improvements.';

      final packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      if (_isNewerVersion(latestVersion, currentVersion)) {
        if (context.mounted) {
          _showUpdateDialog(context, latestVersion, apkUrl, releaseNotes);
        }
      }
    } catch (e) {
      // Silently ignore — don't crash the app if update check fails
      debugPrint('Update check failed: $e');
    }
  }

  static void _showUpdateDialog(
    BuildContext context,
    String newVersion,
    String apkUrl,
    String releaseNotes,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.system_update, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Update Available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version $newVersion is now available.',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              releaseNotes,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri.parse(apkUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}
