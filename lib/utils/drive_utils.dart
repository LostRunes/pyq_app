String extractFolderId(String url) {
  final match = RegExp(r'folders\/([a-zA-Z0-9_-]+)').firstMatch(url);
  if (match == null) {
    throw Exception('Invalid Google Drive folder URL: $url');
  }
  return match.group(1)!;
}
