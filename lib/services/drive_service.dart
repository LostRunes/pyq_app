import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';

class DriveService {
  final GoogleSignIn _googleSignIn;

  DriveService(this._googleSignIn);

  String get apiKey => const String.fromEnvironment('DRIVE_API_KEY');

  // The central upload folder ID specified by the user
  static const String centralUploadFolderId =
      "1_hu36qpVvi-7HZJEJi3JKF597qZepRiA";

  Future<List<dynamic>> fetchFolderContents(String folderId) async {
    final url =
        "https://www.googleapis.com/drive/v3/files"
        "?q='$folderId'+in+parents+and+trashed=false"
        "&key=$apiKey"
        "&fields=files(id,name,mimeType,webViewLink,iconLink,thumbnailLink)";

    final response = await http.get(Uri.parse(url));

    final data = jsonDecode(response.body);

    return data["files"] ?? [];
  }

  Future<String?> findFolderByName(
    String name,
    String parentFolderId,
    String accessToken,
  ) async {
    final nameEscaped = name.replaceAll("'", "\\'");
    final url =
        "https://www.googleapis.com/drive/v3/files"
        "?q=name='$nameEscaped'+and+mimeType='application/vnd.google-apps.folder'+and+'$parentFolderId'+in+parents+and+trashed=false"
        "&fields=files(id)";

    final response = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $accessToken"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final files = data['files'] as List<dynamic>?;
      if (files != null && files.isNotEmpty) {
        return files.first['id'] as String?;
      }
    }
    return null;
  }

  Future<String> createFolder(
    String name,
    String parentFolderId,
    String accessToken,
  ) async {
    final url = "https://www.googleapis.com/drive/v3/files";
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json; charset=UTF-8",
      },
      body: jsonEncode({
        "name": name,
        "mimeType": "application/vnd.google-apps.folder",
        "parents": [parentFolderId],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'] as String;
    } else {
      throw Exception(
        "Failed to create folder in Google Drive: ${response.statusCode} - ${response.body}",
      );
    }
  }

  Future<String?> uploadFile({
    required String filename,
    required String mimeType,
    required List<int> fileBytes,
    required String subjectName,
  }) async {
    GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
    currentUser ??= await _googleSignIn.signInSilently();
    currentUser ??= await _googleSignIn.signIn();
    if (currentUser == null) {
      throw Exception("User is not signed in to Google.");
    }

    // Request the Drive scope.
    // On Android/iOS, if the scope is already granted, requestScopes resolves silently and returns true immediately.
    // canAccessScopes() is not implemented on mobile platforms and throws UnimplementedError.
    final granted = await _googleSignIn.requestScopes(['https://www.googleapis.com/auth/drive.file']);
    if (!granted) {
      throw Exception("Google Drive permission was denied.");
    }
    final auth = await currentUser.authentication;
    final accessToken = auth.accessToken;
    if (accessToken == null) {
      throw Exception("Failed to retrieve Google Access Token.");
    }

    // Find or create the subfolder named after the subject inside the central upload folder
    String? subjectFolderId = await findFolderByName(
      subjectName,
      centralUploadFolderId,
      accessToken,
    );
    subjectFolderId ??= await createFolder(
        subjectName,
        centralUploadFolderId,
        accessToken,
      );

    final url =
        "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart";

    final boundary = "upload_boundary_${DateTime.now().millisecondsSinceEpoch}";
    final header =
        "--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n"
        '{"name": "$filename", "parents": ["$subjectFolderId"]}\r\n\r\n'
        "--$boundary\r\nContent-Type: $mimeType\r\n\r\n";
    final footer = "\r\n--$boundary--\r\n";

    final List<int> bodyBytes = [];
    bodyBytes.addAll(utf8.encode(header));
    bodyBytes.addAll(fileBytes);
    bodyBytes.addAll(utf8.encode(footer));

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "multipart/related; boundary=$boundary",
        "Content-Length": bodyBytes.length.toString(),
      },
      body: bodyBytes,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'] as String?;
    } else {
      throw Exception(
        "Failed to upload to Google Drive: ${response.statusCode} - ${response.body}",
      );
    }
  }
}
