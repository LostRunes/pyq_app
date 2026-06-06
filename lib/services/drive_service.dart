import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DriveService {
  String get apiKey => dotenv.env['DRIVE_API_KEY'] ?? '';

  Future<List<dynamic>> fetchFolderContents(
      String folderId) async {

    final url =
        "https://www.googleapis.com/drive/v3/files"
        "?q='$folderId'+in+parents+and+trashed=false"
        "&key=$apiKey"
        "&fields=files(id,name,mimeType,webViewLink)";

    final response = await http.get(Uri.parse(url));

    final data = jsonDecode(response.body);

    return data["files"] ?? [];
  }

  Future<String?> uploadFile({
    required String filename,
    required String mimeType,
    required List<int> fileBytes,
    required String parentFolderId,
  }) async {
    final url = "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&key=$apiKey";
    
    final boundary = "upload_boundary_${DateTime.now().millisecondsSinceEpoch}";
    final header = "--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n"
        '{"name": "$filename", "parents": ["$parentFolderId"]}\r\n\r\n'
        "--$boundary\r\nContent-Type: $mimeType\r\n\r\n";
    final footer = "\r\n--$boundary--\r\n";

    final List<int> bodyBytes = [];
    bodyBytes.addAll(utf8.encode(header));
    bodyBytes.addAll(fileBytes);
    bodyBytes.addAll(utf8.encode(footer));

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "multipart/related; boundary=$boundary",
        "Content-Length": bodyBytes.length.toString(),
      },
      body: bodyBytes,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'] as String?;
    } else {
      throw Exception("Failed to upload to Google Drive: ${response.statusCode} - ${response.body}");
    }
  }
}
