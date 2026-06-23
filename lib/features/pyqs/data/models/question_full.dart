import 'dart:typed_data';
import 'pyq_source.dart';

class QuestionFull {
  final String text;
  final String difficulty;
  final List<String> imageUrls;
  final List<PyqSource> pyqMeta;
  List<Uint8List>? loadedImages; // Pre-loaded image data for PDF

  QuestionFull({
    required this.text,
    required this.difficulty,
    required this.imageUrls,
    required this.pyqMeta,
    this.loadedImages,
  });
}
