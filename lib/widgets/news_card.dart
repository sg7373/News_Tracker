import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article.dart';
import 'package:news_tracker/services/bookmark_service.dart';

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

  @override
  void didUpdateWidget(covariant NewsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.article.title != widget.article.title) {
      _checkBookmark();
    }
  }

  Future<void> _checkBookmark() async {
    final title = widget.article.title;
    if (title.isEmpty) return;
    final result = await BookmarkService.isBookmarked(title);
    if (mounted) setState(() => isBookmarked = result);
  }

  Future<void> _toggleBookmark() async {
    final title = widget.article.title;
    final articleData = {
      "title": widget.article.title,
      "description": widget.article.description,
      "url": widget.article.url,
      "urlToImage": widget.article.urlToImage,
      "source": {"name": widget.article.sourceName},
      "publishedAt": widget.article.publishedAt.toIso8601String(),
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      _showSnackBar("Could not open link");
    }
  }

  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey)),
      );
    }
    final imageUrl = url.startsWith('http') ? "https://corsproxy.io/?$url" : url;
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('h:mm a \'on\' EEEE, d MMMM y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          margin: EdgeInsets.symmetric(
            vertical: isMobile ? 6 : 10,
            horizontal: isMobile ? 0 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(14),
            boxShadow: isMobile
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: ClipRRect(
            borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ── IMAGE ───────────────────────────────────────────────
                SizedBox(
                  height: isMobile ? screenHeight * 0.30 : 220,
                  width: double.infinity,
                  child: _buildImage(article.urlToImage),
                ),

                /// ── CONTENT ─────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// TITLE
                        Text(
                          article.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 6),

                        /// SOURCE • TIME
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            children: [
                              TextSpan(
                                text: 'short',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              TextSpan(text: '  by '),
                              TextSpan(
                                text: article.sourceName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(text: ' / ${_formatDate(article.publishedAt)}'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// DESCRIPTION
                        Expanded(
                          child: Text(
                            article.description ?? 'No description available.',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 15,
                              height: 1.55,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.fade,
                          ),
                        ),

                        const Divider(height: 1),

                        /// ── ACTION BAR ─────────────────────────────────
                        Row(
                          children: [
                            // Share
                            _iconBtn(
                              icon: Icons.share_outlined,
                              onTap: () => Share.share('${article.title}\n${article.url}'),
                            ),
                            const SizedBox(width: 4),
                            // Bookmark
                            _iconBtn(
                              icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: isBookmarked ? Colors.red : Colors.black54,
                              onTap: _toggleBookmark,
                            ),

                            const Spacer(),

                            // Read more
                            GestureDetector(
                              onTap: () => _launchURL(article.url),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(fontSize: 13, color: Colors.blue[800]),
                                  children: const [
                                    TextSpan(text: 'read more at '),
                                    TextSpan(
                                      text: 'source',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _iconBtn({
    required IconData icon,
    Color color = Colors.black54,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}