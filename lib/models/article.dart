// lib/models/article.dart
class Article {
  final String title;
  final String? description;
  final String? urlToImage;
  final String sourceName;
  final DateTime publishedAt;
  final String url;

  Article({
    required this.title,
    this.description,
    this.urlToImage,
    required this.sourceName,
    required this.publishedAt,
    required this.url,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? 'No Title',
      description: json['text'] ?? json['summary'] ?? '',
      urlToImage: json['image'], // Correct for World News API
      // 🔥 This fix prevents the "NoSuchMethodError: ['name']" crash
      sourceName: (json['source'] != null)
          ? (json['source']['name'] ?? 'News')
          : 'News',
      publishedAt: json['publish_date'] != null
          ? DateTime.parse(json['publish_date'])
          : DateTime.now(),
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'urlToImage': urlToImage,
      'sourceName': sourceName,
      'publishedAt': publishedAt.toIso8601String(),
      'url': url,
    };
  }
}
