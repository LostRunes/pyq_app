class TopicResource {
  final String id;
  final String topicId;
  final String resourceType;
  final String title;
  final String url;

  TopicResource({
    required this.id,
    required this.topicId,
    required this.resourceType,
    required this.title,
    required this.url,
  });

  factory TopicResource.fromJson(Map<String, dynamic> json) => TopicResource(
        id: json['id'] as String,
        topicId: json['topic_id'] as String,
        resourceType: (json['resource_type'] as String?) ?? 'unknown',
        title: (json['title'] as String?) ?? 'No Title',
        url: (json['url'] as String?) ?? '',
      );
}
