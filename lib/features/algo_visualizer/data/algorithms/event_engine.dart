import '../models/viz_event.dart';

class VizStats {
  int comparisons = 0;
  int swaps = 0;
  int writes = 0;
  int iterations = 0;
  int visits = 0;
  int edgeExaminations = 0;

  VizStats copy() => VizStats()
    ..comparisons = comparisons
    ..swaps = swaps
    ..writes = writes
    ..iterations = iterations
    ..visits = visits
    ..edgeExaminations = edgeExaminations;

  void reset() {
    comparisons = 0;
    swaps = 0;
    writes = 0;
    iterations = 0;
    visits = 0;
    edgeExaminations = 0;
  }
}

void applyEvent(List<int> array, VizEvent event) {
  switch (event) {
    case SwapEvent(:final indices):
      final tmp = array[indices[0]];
      array[indices[0]] = array[indices[1]];
      array[indices[1]] = tmp;
    case OverwriteEvent(:final index, :final value):
      array[index] = value;
    default:
      break;
  }
}

void updateStats(VizStats stats, VizEvent event) {
  switch (event) {
    case CompareEvent():
      stats.comparisons++;
      stats.iterations++;
    case SwapEvent():
      stats.swaps++;
      stats.writes += 2;
      stats.iterations++;
    case OverwriteEvent():
      stats.writes++;
      stats.iterations++;
    case VisitEvent():
      stats.visits++;
    case RelaxEvent():
      stats.edgeExaminations++;
    default:
      break;
  }
}

({List<int> array, VizStats stats}) consumeEvents(
  List<int> input,
  Iterable<VizEvent> events,
) {
  final array = List<int>.from(input);
  final stats = VizStats();
  for (final event in events) {
    applyEvent(array, event);
    updateStats(stats, event);
  }
  return (array: array, stats: stats);
}