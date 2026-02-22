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
      title: json['title'] ?? '',
      description: json['description'],
      urlToImage: json['urlToImage'],
      sourceName: json['source']['name'] ?? 'Unknown',
      publishedAt: DateTime.parse(json['publishedAt']),
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'urlToImage': urlToImage,
      'source': {'name': sourceName},
      'publishedAt': publishedAt.toIso8601String(),
      'url': url,
    };
  }
}