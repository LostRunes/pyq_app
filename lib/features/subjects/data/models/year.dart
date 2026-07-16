import 'package:hive/hive.dart';

part 'year.g.dart';

@HiveType(typeId: 1)
class Year extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  Year({required this.id, required this.name});

  factory Year.fromJson(Map<String, dynamic> json) =>
      Year(id: json['id'] as String, name: json['name'] as String);
}
