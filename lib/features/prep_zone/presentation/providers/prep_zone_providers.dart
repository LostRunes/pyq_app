import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrepZoneSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final prepZoneSearchProvider = NotifierProvider<PrepZoneSearchNotifier, String>(
  PrepZoneSearchNotifier.new,
);
