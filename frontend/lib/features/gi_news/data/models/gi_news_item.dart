class GINewsItem {
  const GINewsItem({
    required this.id,
    required this.title,
    required this.articleUrl,
    required this.sourceName,
    required this.publishedAt,
    required this.topic,
    this.imageUrl,
    this.description,
  });

  final String id;
  final String title;
  final String articleUrl;
  final String sourceName;
  final DateTime publishedAt;
  final String topic;
  final String? imageUrl;
  final String? description;
}
