class Article {
  final String title;
  final String? description;
  final String? urlToImage;
  final String url;
  final String sourceName;
  final DateTime publishedAt;

  Article({
    required this.title,
    this.description,
    this.urlToImage,
    required this.url,
    required this.sourceName,
    required this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? '',
      description: json['description'],
      urlToImage: json['urlToImage'],
      url: json['url'] ?? '',
      sourceName: json['source']?['name'] ?? '',
      publishedAt: DateTime.parse(json['publishedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "description": description,
      "urlToImage": urlToImage,
      "url": url,
      "source": {"name": sourceName},
      "publishedAt": publishedAt.toIso8601String(),
    };
  }
}