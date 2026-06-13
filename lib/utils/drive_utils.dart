String extractFolderId(String url) {
  final match = RegExp(r'folders\/([a-zA-Z0-9_-]+)').firstMatch(url);
  if (match == null) {
    throw Exception('Invalid Google Drive folder URL: $url');
  }
  return match.group(1)!;
}

String getPreviewUrl(String url) {
  if (url.contains("drive.google.com")) {
    if (url.contains("/folders/")) {
      return url;
    }
    String? id;
    final fileIdRegExp = RegExp(r'/file/d/([^/]+)');
    final match = fileIdRegExp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      id = match.group(1);
    } else {
      final idRegExp = RegExp(r'[?&]id=([^&]+)');
      final matchId = idRegExp.firstMatch(url);
      if (matchId != null && matchId.groupCount >= 1) {
        id = matchId.group(1);
      }
    }
    if (id != null) {
      // Route through Google Docs Viewer which renders the file directly and bypasses account choosing
      final rawDownloadUrl =
          "https://drive.google.com/uc?export=download&id=$id";
      return "https://docs.google.com/viewer?embedded=true&url=${Uri.encodeComponent(rawDownloadUrl)}";
    }
  }
  return url;
}
