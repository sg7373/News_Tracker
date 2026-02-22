import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article.dart';
import 'package:inshorts_clone/services/bookmark_service.dart';

class NewsCard extends StatefulWidget {
  final Article article;
  final bool isActive;

  const NewsCard({
    super.key,
    required this.article,
    this.isActive = false,
  });

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  bool isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  // 🌟 FIX: Updates bookmark icon if you scroll fast and cards are reused
  @override
  void didUpdateWidget(covariant NewsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.article.title != widget.article.title) {
      _checkBookmark();
    }
  }

  Future<void> _checkBookmark() async {
    final title = widget.article.title ?? "";
    if (title.isEmpty) return;
    final result = await BookmarkService.isBookmarked(title);
    if (mounted) setState(() => isBookmarked = result);
  }

  Future<void> _toggleBookmark() async {
    final title = widget.article.title ?? "Untitled";
    
    // 🌟 ENHANCEMENT: Prepare data safely
    final articleData = {
      "title": widget.article.title,
      "description": widget.article.description,
      "url": widget.article.url,
      "urlToImage": widget.article.urlToImage,
      "sourceName": widget.article.sourceName,
      "publishedAt": widget.article.publishedAt?.toIso8601String(),
    };

    if (isBookmarked) {
      await BookmarkService.removeBookmark(title);
      _showSnackBar("Removed from bookmarks");
    } else {
      await BookmarkService.addBookmark(articleData);
      _showSnackBar("Added to bookmarks");
    }

    if (mounted) setState(() => isBookmarked = !isBookmarked);
  }

  // 🌟 NEW: Helper for user feedback
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    try {
      // 🌟 FIX: externalApplication is safer for web/mobile compatibility
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showSnackBar("Could not open link");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 FIX: Dynamic height to prevent overflow on small screens
    double cardHeight = MediaQuery.of(context).size.height * 0.28;
    if (cardHeight < 200) cardHeight = 200; 

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750),
        child: Container(
          height: cardHeight,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect( // 🌟 Added ClipRRect here to ensure child content doesn't bleed out
            borderRadius: BorderRadius.circular(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 IMAGE SECTION
                SizedBox(
                  width: 140,
                  height: double.infinity,
                  child: _buildImage(widget.article.urlToImage),
                ),

                /// 🔹 CONTENT SECTION
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.article.title ?? "No Title",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${widget.article.sourceName ?? 'News'} • ${_formatDate(widget.article.publishedAt)}",
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            widget.article.description ?? "No description available.",
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, height: 1.3),
                          ),
                        ),
                        
                        /// 🔹 ACTION BAR
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.share_outlined, size: 20),
                                  onPressed: () => Share.share('${widget.article.title}\n${widget.article.url}'),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.only(right: 15),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                    size: 20,
                                    color: isBookmarked ? Colors.blue : Colors.black,
                                  ),
                                  onPressed: _toggleBookmark,
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => _launchURL(widget.article.url ?? ""),
                              child: const Text("READ MORE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🌟 NEW: Cleaner Image Builder with CORS handling
  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported));
    }
    
    // For Web Compatibility
    final imageUrl = url.startsWith('http') ? "https://corsproxy.io/?$url" : url;

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  // 🌟 NEW: Safe Date Formatting
  String _formatDate(DateTime? date) {
    if (date == null) return "Just now";
    return DateFormat('MMM d, h:mm a').format(date);
  }
}