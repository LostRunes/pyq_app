import 'package:flutter_riverpod/flutter_riverpod.dart';

class UtilitiesSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateSearch(String query) => state = query;
}

final utilitiesSearchProvider = NotifierProvider<UtilitiesSearchNotifier, String>(
  UtilitiesSearchNotifier.new,
);
