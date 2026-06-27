import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrepZoneSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateSearch(String query) => state = query;
}

final prepZoneSearchProvider = NotifierProvider<PrepZoneSearchNotifier, String>(
  PrepZoneSearchNotifier.new,
);
