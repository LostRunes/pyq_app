import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'ddcwfyevf';
  static const String uploadPreset = 'student_doubts_upload';

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final String targetPath = '${imageFile.path}_compressed.webp';
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 70,
        format: CompressFormat.webp,
      );

      if (compressedFile == null) {
        return null;
      }

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;

      request.files.add(
        await http.MultipartFile.fromPath('file', compressedFile.path),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseData);
        return jsonData['secure_url'];
      }

      return null;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }
}
