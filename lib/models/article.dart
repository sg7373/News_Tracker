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
    // NewsAPI's 'content' field often has more substance, but ends with '[+1234 chars]'.
    String? contentData = json['content'];
    if (contentData != null) {
      contentData = contentData.replaceAll(RegExp(r'\[\+\d+\s+chars\]'), '').trim();
      if (contentData.isNotEmpty && !contentData.endsWith('.')) {
        contentData += '...';
      } else if (contentData.isNotEmpty) {
        contentData += '..';
      }
    }
    
    // Prioritize cleaned content > regular description
    String? finalDescription = (contentData != null && contentData.isNotEmpty) 
        ? contentData 
        : json['description'];

    return Article(
      title: json['title'] ?? '',
      description: finalDescription,
      urlToImage: json['urlToImage'],
      url: json['url'] ?? '',
      sourceName: json['source']?['name'] ?? '',
      publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt']) : DateTime.now(),
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
