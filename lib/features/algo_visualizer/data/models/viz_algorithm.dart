enum InputKind { array, graph }

class AlgorithmMeta {
  const AlgorithmMeta({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.complexity,
    required this.inputKind,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final String complexity;
  final InputKind inputKind;
}