class ImageItem {
  final String id;
  final String questionId;
  final String imageUrl;
  final int orderIndex;

  ImageItem({required this.id, required this.questionId, required this.imageUrl, required this.orderIndex});

  factory ImageItem.fromJson(Map<String, dynamic> json) => ImageItem(
        id: json['id'] as String,
        questionId: json['question_id'] as String,
        imageUrl: json['image_url'] as String,
        orderIndex: json['order_index'] as int,
      );
}
