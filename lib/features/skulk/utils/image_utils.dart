import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageUtils {
  static Future<File?> compressImage(File file) async {
    final path = file.path;
    final targetPath = '${path}_compressed.webp';

    try {
      final compressed = await FlutterImageCompress.compressAndGetFile(
        path,
        targetPath,
        quality: 55,
        minWidth: 1280,
        minHeight: 1280,
        format: CompressFormat.webp,
      );

      if (compressed == null) return null;

      return File(compressed.path);
    } catch (e) {
      // Fallback to original file if compression fails
      return file;
    }
  }
}
