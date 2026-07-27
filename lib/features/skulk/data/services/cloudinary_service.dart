import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'ddcwfyevf';

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

      // 1. Fetch signed parameters from Supabase Edge Function on the secondary Supabase project
      final signUri = Uri.parse(
        '${const String.fromEnvironment('SUPABASE_2_URL')}/functions/v1/cloudinary-sign',
      );
      final signResponse = await http.post(
        signUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${const String.fromEnvironment('SUPABASE_2_KEY')}',
        },
      );

      if (signResponse.statusCode != 200) {
        if (kDebugMode) {
          print('Failed to fetch Cloudinary signature: ${signResponse.statusCode} - ${signResponse.body}');
        }
        return null;
      }

      final signData = jsonDecode(signResponse.body);
      final String signature = signData['signature'];
      final String timestamp = signData['timestamp'];
      final String apiKey = signData['apiKey'];
      final String uploadPreset = signData['uploadPreset'];

      // 2. Perform the signed upload to Cloudinary
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
      request.fields['api_key'] = apiKey;

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
      if (kDebugMode) print('Cloudinary upload error: $e');
      return null;
    }
  }
}
