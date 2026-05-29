class Year {
  final String id;
  final String name;

  Year({required this.id, required this.name});

  factory Year.fromJson(Map<String, dynamic> json) => Year(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}
