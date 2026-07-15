import 'package:hive/hive.dart';

part 'branch.g.dart';

@HiveType(typeId: 0)
class Branch extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  Branch({required this.id, required this.name});

  factory Branch.fromJson(Map<String, dynamic> json) =>
      Branch(id: json['id'] as String, name: json['name'] as String);
}
