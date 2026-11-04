import '../models/viz_event.dart';

Iterable<VizEvent> bubbleSort(List<int> input) sync* {
  final a = List<int>.from(input);
  for (var end = a.length - 1; end > 0; end--) {
    var moved = false;
    for (var j = 0; j < end; j++) {
      yield CompareEvent([j, j + 1], text: 'Comparing ${a[j]} and ${a[j + 1]}');
      if (a[j] > a[j + 1]) {
        final tmp = a[j];
        a[j] = a[j + 1];
        a[j + 1] = tmp;
        yield SwapEvent([j, j + 1], text: 'Swapping positions $j and ${j + 1}');
        moved = true;
      }
    }
    if (!moved) break;
    yield MarkSortedEvent([end], text: 'Position $end is final');
  }
  yield MarkSortedEvent(
    [for (var i = 0; i < a.length; i++) i],
    text: 'Array sorted',
  );
}

Iterable<VizEvent> mergeSort(List<int> input) sync* {
  final a = List<int>.from(input);

  Iterable<VizEvent> merge(int lo, int mid, int hi) sync* {
    final left = a.sublist(lo, mid + 1);
    final right = a.sublist(mid + 1, hi + 1);
    yield MessageEvent('Merging [${left.join(', ')}] and [${right.join(', ')}]');
    var i = 0, j = 0, k = lo;
    while (i < left.length && j < right.length) {
      yield CompareEvent(
        [lo + i, mid + 1 + j],
        text: 'Comparing ${left[i]} and ${right[j]}',
      );
      final value = left[i] <= right[j] ? left[i++] : right[j++];
      a[k] = value;
      yield OverwriteEvent(k, value, text: 'Writing $value to index $k');
      k++;
    }
    while (i < left.length) {
      a[k] = left[i];
      yield OverwriteEvent(k, left[i], text: 'Writing ${left[i]} to index $k');
      i++;
      k++;
    }
    while (j < right.length) {
      a[k] = right[j];
      yield OverwriteEvent(k, right[j], text: 'Writing ${right[j]} to index $k');
      j++;
      k++;
    }
  }

  Iterable<VizEvent> sort(int lo, int hi) sync* {
    if (lo >= hi) return;
    final mid = (lo + hi) ~/ 2;
    yield RangeEvent(lo, hi, text: 'Splitting range $lo-$hi');
    yield* sort(lo, mid);
    yield* sort(mid + 1, hi);
    yield* merge(lo, mid, hi);
  }

  yield* sort(0, a.length - 1);
  yield MarkSortedEvent(
    [for (var i = 0; i < a.length; i++) i],
    text: 'Array sorted',
  );
}

Iterable<VizEvent> selectionSort(List<int> input) sync* {
  final a = List<int>.from(input);
  for (var i = 0; i < a.length; i++) {
    var min = i;
    for (var j = i + 1; j < a.length; j++) {
      yield CompareEvent([min, j], text: 'Comparing ${a[min]} and ${a[j]}');
      if (a[j] < a[min]) min = j;
    }
    if (min != i) {
      final tmp = a[i];
      a[i] = a[min];
      a[min] = tmp;
      yield SwapEvent([i, min], text: 'Swapping minimum into position $i');
    }
    yield MarkSortedEvent([i]);
  }
}

Iterable<VizEvent> insertionSort(List<int> input) sync* {
  final a = List<int>.from(input);
  for (var i = 1; i < a.length; i++) {
    final value = a[i];
    var j = i - 1;
    while (j >= 0) {
      yield CompareEvent([j, j + 1], text: 'Comparing ${a[j]} and $value');
      if (a[j] <= value) break;
      a[j + 1] = a[j];
      yield OverwriteEvent(j + 1, a[j], text: 'Moving ${a[j]} right');
      j--;
    }
    a[j + 1] = value;
    yield OverwriteEvent(j + 1, value, text: 'Inserting $value');
  }
  yield MarkSortedEvent([for (var i = 0; i < a.length; i++) i]);
}

Iterable<VizEvent> heapSort(List<int> input) sync* {
  final a = List<int>.from(input);

  Iterable<VizEvent> heap(int n, int i) sync* {
    var largest = i;
    final l = 2 * i + 1;
    final r = l + 1;
    if (l < n) {
      yield CompareEvent(
        [l, largest],
        text: 'Heapifying subtree rooted at index $i',
      );
      if (a[l] > a[largest]) largest = l;
    }
    if (r < n) {
      yield CompareEvent([r, largest]);
      if (a[r] > a[largest]) largest = r;
    }
    if (largest != i) {
      final tmp = a[i];
      a[i] = a[largest];
      a[largest] = tmp;
      yield SwapEvent([i, largest]);
      yield* heap(n, largest);
    }
  }

  for (var i = a.length ~/ 2 - 1; i >= 0; i--) {
    yield* heap(a.length, i);
  }
  for (var end = a.length - 1; end > 0; end--) {
    final tmp = a[0];
    a[0] = a[end];
    a[end] = tmp;
    yield SwapEvent([0, end]);
    yield MarkSortedEvent([end]);
    yield* heap(end, 0);
  }
  yield MarkSortedEvent([for (var i = 0; i < a.length; i++) i]);
}

Iterable<VizEvent> quickSort(List<int> input) sync* {
  final a = List<int>.from(input);

  (int, List<VizEvent>) partition(int lo, int hi) {
    final events = <VizEvent>[];
    final pivot = a[hi];
    events.add(PivotEvent(hi, text: 'Pivot selected: $pivot'));
    var i = lo;
    for (var j = lo; j < hi; j++) {
      events.add(PointersEvent(
        left: i,
        right: j,
        boundary: hi,
        text: 'Pointers: left $i, right $j',
      ));
      events.add(CompareEvent([j, hi], text: 'Comparing ${a[j]} with pivot $pivot'));
      if (a[j] < pivot) {
        final tmp = a[i];
        a[i] = a[j];
        a[j] = tmp;
        events.add(SwapEvent([i, j], text: 'Swapping $i and $j'));
        i++;
      }
    }
    final tmp = a[i];
    a[i] = a[hi];
    a[hi] = tmp;
    events.add(SwapEvent([i, hi], text: 'Placing pivot $pivot at index $i'));
    return (i, events);
  }

  Iterable<VizEvent> sort(int lo, int hi) sync* {
    if (lo >= hi) return;
    yield RangeEvent(lo, hi, text: 'Partitioning range [$lo, $hi]');
    final (pivotIndex, events) = partition(lo, hi);
    for (final event in events) {
      yield event;
    }
    yield* sort(lo, pivotIndex - 1);
    yield* sort(pivotIndex + 1, hi);
  }

  yield* sort(0, a.length - 1);
  yield MarkSortedEvent(
    [for (var i = 0; i < a.length; i++) i],
    text: 'Array sorted',
  );
}