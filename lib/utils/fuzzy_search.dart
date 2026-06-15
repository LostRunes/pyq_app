class FuzzySearch {
  /// Checks if the [query] matches the [target] string fuzzily.
  /// First does a direct check, then splits the query into words and checks
  /// if each word is either a direct substring or a subsequence of characters
  /// within the target.
  static bool matches(String? target, String query) {
    if (query.isEmpty) return true;
    if (target == null || target.isEmpty) return false;

    final cleanTarget = target.toLowerCase();
    final cleanQuery = query.trim().toLowerCase();

    // 1. Direct substring check
    if (cleanTarget.contains(cleanQuery)) return true;

    // 2. Tokenized check
    final queryWords = cleanQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (queryWords.isEmpty) return true;

    for (final word in queryWords) {
      if (!cleanTarget.contains(word)) {
        // Check subsequence of characters
        int charIdx = 0;
        for (int i = 0; i < cleanTarget.length; i++) {
          if (cleanTarget[i] == word[charIdx]) {
            charIdx++;
            if (charIdx == word.length) break;
          }
        }
        if (charIdx < word.length) {
          return false; // Word is not a subsequence
        }
      }
    }

    return true;
  }
}
