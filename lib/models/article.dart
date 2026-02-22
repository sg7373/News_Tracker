class Article {
  final String? title;
  final String? description;
  final String? url;
  final String? urlToImage;
  final String? sourceName;
  final DateTime? publishedAt;

  Article({
    this.title,
    this.description,
    this.url,
    this.urlToImage,
    this.sourceName,
    this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'],
      description: json['description'],
      url: json['url'],
      urlToImage: json['urlToImage'],
      sourceName: json['source']['name'],  // 🔹 This is where 'sourceName' comes from
      publishedAt: DateTime.tryParse(json['publishedAt'] ?? ''),
    );
  }
}