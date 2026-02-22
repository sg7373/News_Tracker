import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article.dart';

class NewsCard extends StatelessWidget {
  final Article article;
  final bool isActive;

  const NewsCard({
    super.key,
    required this.article,
    this.isActive = false,
  });

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Height so roughly 3 cards fit per screen
    double cardHeight = MediaQuery.of(context).size.height * 0.30;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750),
        child: Container(
          height: cardHeight,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 LEFT IMAGE
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: article.urlToImage != null && article.urlToImage!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: article.urlToImage!,
                          width: 110,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          httpHeaders: const {
                            "User-Agent":
                                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
                          },
                          placeholder: (context, url) => Container(
                            width: 110,
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 110,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 25),
                          ),
                        )
                      : Container(
                          width: 110,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 25),
                        ),
                ),

                const SizedBox(width: 12),

                /// 🔹 RIGHT CONTENT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title ?? "No Title",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "short by ${article.sourceName ?? 'Unknown'} / ${DateFormat('MMM d, h:mm a').format(article.publishedAt ?? DateTime.now())}",
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),

                      // 🔹 Flexible description to avoid overflow
                      Flexible(
                        child: Text(
                          article.description ?? "",
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      /// 🔹 FOOTER ACTIONS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () => Share.share(
                                    '${article.title ?? ""}\n${article.url ?? ""}'),
                                child: const Icon(Icons.share, size: 18, color: Colors.blueGrey),
                              ),
                              const SizedBox(width: 20),
                              InkWell(
                                onTap: () {
                                  if (article.url != null && article.url!.isNotEmpty) {
                                    _launchURL(article.url!);
                                  }
                                },
                                child: const Icon(Icons.open_in_browser,
                                    size: 18, color: Colors.blueGrey),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              if (article.url != null && article.url!.isNotEmpty) {
                                _launchURL(article.url!);
                              }
                            },
                            child: const Text(
                              "read more",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}