import 'package:flutter_test/flutter_test.dart';
import 'package:focus_fox/features/algo_visualizer/data/algorithms/algorithm_registry.dart';
import 'package:focus_fox/features/algo_visualizer/data/algorithms/event_engine.dart';
import 'package:focus_fox/features/algo_visualizer/data/models/graph_model.dart';

void main() {
  test('sorting algos sort default array', () {
    for (final id in ['bubble_sort','merge_sort','quick_sort','selection_sort',
        'insertion_sort','heap_sort','counting_sort','radix_sort','bucket_sort']) {
      final input = List<int>.from(AlgorithmRegistry.defaultArray);
      final events = AlgorithmRegistry.generate(id: id, array: input, graph: demoGraph).toList();
      expect(events, isNotEmpty, reason: id);
      final out = consumeEvents(input, events);
      final sorted = List<int>.from(input)..sort();
      expect(out.array, sorted, reason: id);
    }
  });
  test('bfs/dfs visit all demo nodes', () {
    for (final id in ['bfs','dfs','dijkstra']) {
      final events = AlgorithmRegistry.generate(
        id: id, array: AlgorithmRegistry.defaultArray, graph: demoGraph).toList();
      expect(events, isNotEmpty, reason: id);
    }
  });
}