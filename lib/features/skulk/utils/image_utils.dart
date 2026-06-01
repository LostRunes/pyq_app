import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageUtils {
  static Future<File?> compressImage(
    File file,
  ) async {
    return compute(
      _compressInBackground,
      file.path,
    );
  }

  static Future<File?> _compressInBackground(
    String path,
  ) async {
    final targetPath = '${path}_compressed.webp';

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
  }
}
