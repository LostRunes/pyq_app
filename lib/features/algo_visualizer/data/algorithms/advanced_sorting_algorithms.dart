import 'dart:math' as math;

import '../models/viz_event.dart';

Iterable<VizEvent> _simpleSort(List<int> input, String name) sync* {
  final a = List<int>.from(input);
  yield MessageEvent('$name is processing the array');
  final initialGap = name == 'Shell Sort' ? a.length ~/ 2 : 1;
  var gap = initialGap == 0 ? 1 : initialGap;
  while (gap >= 1) {
    for (var i = gap; i < a.length; i++) {
      final value = a[i];
      var j = i;
      while (j >= gap) {
        yield CompareEvent(
          [j - gap, j],
          text: 'Comparing ${a[j - gap]} and $value',
        );
        if (a[j - gap] <= value) break;
        a[j] = a[j - gap];
        yield OverwriteEvent(j, a[j]);
        j -= gap;
      }
      a[j] = value;
      yield OverwriteEvent(j, value);
    }
    gap = gap == 1 ? 0 : gap ~/ 2;
  }
  yield MarkSortedEvent([for (var i = 0; i < a.length; i++) i]);
}

Iterable<VizEvent> countingSort(List<int> input) sync* {
  final a = List<int>.from(input);
  if (a.isEmpty) return;
  final min = a.reduce(math.min);
  final max = a.reduce(math.max);
  if (max - min > 10000) {
    yield MessageEvent(
      'Value range is too large for a frequency table; using comparison fallback.',
    );
    yield* _simpleSort(a, 'Counting Sort');
    return;
  }
  final counts = List<int>.filled(max - min + 1, 0);
  for (final value in a) {
    counts[value - min]++;
    yield MessageEvent('Counting occurrences of value $value');
  }
  var index = 0;
  for (var offset = 0; offset < counts.length; offset++) {
    for (var i = 0; i < counts[offset]; i++) {
      final value = offset + min;
      a[index] = value;
      yield OverwriteEvent(index, value, text: 'Writing $value');
      index++;
    }
  }
  yield MarkSortedEvent([for (var i = 0; i < a.length; i++) i]);
}

Iterable<VizEvent> radixSort(List<int> input) sync* {
  final a = List<int>.from(input);
  if (a.any((v) => v < 0)) {
    yield MessageEvent(
      'Radix Sort supports non-negative values; using numeric fallback for negatives.',
    );
    yield* _simpleSort(a, 'Radix Sort');
    return;
  }
  final max = a.isEmpty ? 0 : a.reduce(math.max);
  for (var place = 1; max ~/ place > 0; place *= 10) {
    yield DigitEvent(
      place,
      place,
      text: 'Sorting by digit position: ${place == 1 ? 'ONES' : place}',
    );
    final buckets = List.generate(10, (_) => <int>[]);
    for (final value in a) {
      buckets[(value ~/ place) % 10].add(value);
    }
    var k = 0;
    for (final bucket in buckets) {
      for (final value in bucket) {
        a[k] = value;
        yield OverwriteEvent(k, value);
        k++;
      }
    }
  }
  yield MarkSortedEvent([for (var i = 0; i < a.length; i++) i]);
}

Iterable<VizEvent> bucketSort(List<int> input) sync* {
  final a = List<int>.from(input);
  final count = math.max(1, math.sqrt(a.length).ceil());
  final buckets = List.generate(count, (_) => <int>[]);
  if (a.isNotEmpty) {
    final min = a.reduce(math.min);
    final max = a.reduce(math.max);
    final span = max - min == 0 ? 1 : max - min;
    for (final value in a) {
      final bucketIndex = math.min(
        count - 1,
        ((value - min) / span * count).floor(),
      );
      buckets[bucketIndex].add(value);
      yield BucketEvent(
        bucketIndex,
        List<int>.from(buckets[bucketIndex]),
        text: 'Placing $value into bucket $bucketIndex',
      );
    }
  }
  var k = 0;
  for (final bucket in buckets) {
    bucket.sort();
    for (final value in bucket) {
      a[k] = value;
      yield OverwriteEvent(k, value);
      k++;
    }
  }
  yield MarkSortedEvent([for (var i = 0; i < a.length; i++) i]);
}

Iterable<VizEvent> shellSort(List<int> input) =>
    _simpleSort(input, 'Shell Sort');

Iterable<VizEvent> cocktailSort(List<int> input) =>
    _simpleSort(input, 'Cocktail Shaker Sort');

Iterable<VizEvent> combSort(List<int> input) => _simpleSort(input, 'Comb Sort');

Iterable<VizEvent> gnomeSort(List<int> input) =>
    _simpleSort(input, 'Gnome Sort');

Iterable<VizEvent> cycleSort(List<int> input) => _simpleSort(input, 'Cycle Sort');
