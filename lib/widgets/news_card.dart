import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article.dart';
import '../services/bookmark_service.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';

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
  bool _isHoveringReadMore = false;

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

    // 🛑 CHECK AUTH STATUS
    if (AuthService().currentUser == null) {
      _showLoginRequiredDialog();
      return;
    }

    if (isBookmarked) {
      await BookmarkService.removeBookmark(title);
      _showSnackBar("Removed from bookmarks");
    } else {
      await BookmarkService.addBookmark(articleData);
      _showSnackBar("Added to bookmarks");
    }
    if (mounted) setState(() => isBookmarked = !isBookmarked);
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please Sign In or Create an Account to save news articles to your bookmarks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log In / Sign Up', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
      await launchUrl(url, mode: LaunchMode.inAppWebView);
    } catch (_) {
      _showSnackBar("Could not open link");
    }
  }

  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) {
      return _buildPlaceholder();
    }

    // Normalise protocol-relative URLs
    String imageUrl = url;
    if (url.startsWith('//')) {
      imageUrl = 'https:$url';
    }

    if (!imageUrl.startsWith('http')) {
      return _buildPlaceholder();
    }

    // 3-tier proxy fallback:
    //  1. images.weserv.nl  — image-optimised CDN proxy, most reliable
    //  2. corsproxy.io      — generic CORS proxy
    //  3. direct URL        — last resort (may be blocked by CORS)
    final weservUrl  = 'https://images.weserv.nl/?url=${Uri.encodeComponent(imageUrl)}&w=800&output=jpg&q=80';
    final corsUrl    = 'https://corsproxy.io/?${Uri.encodeComponent(imageUrl)}';
    final directUrl  = imageUrl;

    return _ProxyImage(
      proxies: [weservUrl, corsUrl, directUrl],
      placeholder: _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1504711434969-e33886168f5c?q=80&w=1000&auto=format&fit=crop'),
          fit: BoxFit.cover,
          opacity: 0.3,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, color: Colors.grey, size: 40),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Image Not Available",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('hh:mm a \'on\' EEEE, d MMMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 800;

    // We build the layout shown in the user's screenshot
    // A horizontally stacked Row with Image on left, Content on right
    
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850), // Matches desktop News Tracker view
        child: Container(
          height: isMobile ? screenHeight * 0.85 : 300, // Reduced height for the horizontal card on desktop
          margin: EdgeInsets.symmetric(
            vertical: isMobile ? 6 : 10,
            horizontal: isMobile ? 0 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: isMobile
                ? _buildMobileLayout(article, screenHeight)
                : _buildDesktopLayout(article),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(Article article, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: screenHeight * 0.35,
          width: double.infinity,
          child: _buildImage(article.urlToImage),
        ),
        Expanded(child: _buildContent(article, true)),
      ],
    );
  }

  Widget _buildDesktopLayout(Article article) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 320,
          height: double.infinity,
          child: _buildImage(article.urlToImage),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: _buildContent(article, false),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(Article article, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          Text(
            article.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.w400,
              height: 1.25,
              color: const Color(0xff44444d),
            ),
          ),
          
          const SizedBox(height: 8),

          /// SOURCE • TIME
          Flexible(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Color(0xff808290)),
                children: [
                  const TextSpan(
                    text: 'news',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' by '),
                  TextSpan(
                    text: article.sourceName.isEmpty ? 'Unknown' : article.sourceName,
                  ),
                  TextSpan(text: ' / ${_formatDate(article.publishedAt)}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// DESCRIPTION
          Expanded(
            child: Text(
              article.description ?? 'No description available for this article.',
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w300,
                color: Color(0xff44444d),
              ),
              overflow: TextOverflow.fade,
            ),
          ),

          const SizedBox(height: 8),

          /// ACTION BAR (read more)
          Row(
            children: [
              // Bottom left text for read more
              if (article.url.isNotEmpty)
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _isHoveringReadMore = true),
                    onExit: (_) => setState(() => _isHoveringReadMore = false),
                    child: GestureDetector(
                      onTap: () => _launchURL(article.url),
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 12, 
                            color: _isHoveringReadMore ? Colors.blue[700] : Colors.black87,
                            decoration: _isHoveringReadMore ? TextDecoration.underline : TextDecoration.none,
                          ),
                          children: [
                            const TextSpan(text: 'read more at '),
                            TextSpan(
                              text: article.sourceName.isEmpty ? 'source' : article.sourceName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              _iconBtn(
                icon: Icons.share_outlined,
                onTap: () => Share.share('${article.title}\n${article.url}'),
              ),
              _iconBtn(
                icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? Colors.red : Colors.black54,
                onTap: _toggleBookmark,
              ),
            ],
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Multi-proxy image widget: tries each proxy URL in order, shows placeholder
// only after ALL options are exhausted.
// ─────────────────────────────────────────────────────────────────────────────
class _ProxyImage extends StatefulWidget {
  final List<String> proxies;
  final Widget placeholder;

  const _ProxyImage({required this.proxies, required this.placeholder});

  @override
  State<_ProxyImage> createState() => _ProxyImageState();
}

class _ProxyImageState extends State<_ProxyImage> {
  int _proxyIndex = 0;

  // ✅ Defer setState to AFTER the current build frame to avoid
  // "setState() called during build" crash from Image.errorBuilder.
  void _onError() {
    if (!mounted) return;
    if (_proxyIndex < widget.proxies.length - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _proxyIndex++);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_proxyIndex >= widget.proxies.length) return widget.placeholder;

    final url = widget.proxies[_proxyIndex];
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
            color: Colors.red,
          ),
        );
      },
      errorBuilder: (_, __, ___) {
        _onError(); // deferred — safe to call during build
        return widget.placeholder;
      },
    );
  }
}