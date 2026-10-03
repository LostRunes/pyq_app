import '../models/viz_event.dart';

Iterable<VizEvent> binarySearch(List<int> sorted, int target) sync* {
  var lo = 0;
  var hi = sorted.length - 1;
  yield MessageEvent('Searching for $target in ${sorted.length} sorted values');
  while (lo <= hi) {
    final mid = (lo + hi) ~/ 2;
    yield RangeEvent(lo, hi, text: 'Searching [$lo..$hi]');
    yield PointersEvent(left: lo, mid: mid, right: hi, text: 'lo=$lo, mid=$mid, hi=$hi');
    yield CompareEvent([mid], text: '${sorted[mid]} vs target $target');
    if (sorted[mid] == target) {
      yield MarkSortedEvent([mid], text: 'Found $target at index $mid');
      yield MessageEvent('Target found at index $mid');
      return;
    }
    if (sorted[mid] < target) {
      yield MessageEvent('${sorted[mid]} < $target, ignoring left half');
      lo = mid + 1;
    } else {
      yield MessageEvent('${sorted[mid]} > $target, ignoring right half');
      hi = mid - 1;
    }
  }
  yield MessageEvent('Target $target is not in the array');
}