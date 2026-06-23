import 'package:flutter_riverpod/flutter_riverpod.dart';

class UtilitiesSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final utilitiesSearchProvider = NotifierProvider<UtilitiesSearchNotifier, String>(
  UtilitiesSearchNotifier.new,
);
