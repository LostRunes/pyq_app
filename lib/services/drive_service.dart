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
}
