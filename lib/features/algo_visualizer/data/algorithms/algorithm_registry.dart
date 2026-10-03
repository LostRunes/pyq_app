import '../models/graph_model.dart';
import '../models/viz_algorithm.dart';
import '../models/viz_event.dart';
import 'advanced_sorting_algorithms.dart';
import 'graph_algorithms.dart';
import 'search_algorithms.dart';
import 'sorting_algorithms.dart';

class AlgorithmRegistry {
  AlgorithmRegistry._();

  static const List<int> defaultArray = [29, 10, 14, 37, 14, 22, 8, 31];

  static const List<AlgorithmMeta> all = [
    AlgorithmMeta(
      id: 'bubble_sort',
      name: 'Bubble Sort',
      category: 'Sorting',
      description: 'Repeatedly swaps adjacent values that are out of order.',
      complexity: 'O(n²)',
      inputKind: InputKind.array,
    ),
    AlgorithmMeta(
      id: 'merge_sort',
      name: 'Merge Sort',
      category: 'Sorting',
      description: 'Splits the array in half, sorts, then merges ordered halves.',
      complexity: 'O(n log n)',
      inputKind: InputKind.array,
    ),
    AlgorithmMeta(
      id: 'quick_sort',
      name: 'Quick Sort',
      category: 'Sorting',
      description: 'Partitions around a pivot, then sorts each side.',
      complexity: 'O(n log n)',
      inputKind: InputKind.array,
    ),
    AlgorithmMeta(
      id: 'binary_search',
      name: 'Binary Search',
      category: 'Searching',
      description: 'Halves the search range on every comparison.',
      complexity: 'O(log n)',
      inputKind: InputKind.array,
    ),
    AlgorithmMeta(
      id: 'bfs',
      name: 'BFS',
      category: 'Graph',
      description: 'Explores level by level using a queue.',
      complexity: 'O(V + E)',
      inputKind: InputKind.graph,
    ),
    AlgorithmMeta(
      id: 'dfs',
      name: 'DFS',
      category: 'Graph',
      description: 'Explores deep first using a stack.',
      complexity: 'O(V + E)',
      inputKind: InputKind.graph,
    ),
    AlgorithmMeta(
      id: 'dijkstra',
      name: 'Dijkstra',
      category: 'Graph',
      description: 'Finds shortest paths using the closest unsettled node.',
      complexity: 'O((V + E) log V)',
      inputKind: InputKind.graph,
    ),
    AlgorithmMeta(
      id: 'selection_sort',
      name: 'Selection Sort',
      category: 'Sorting',
      description: 'Selects the minimum and swaps it into place.',
      complexity: 'O(n²)',
      inputKind: InputKind.array,
    ),
    AlgorithmMeta(
      id: 'insertion_sort',
      name: 'Insertion Sort',
      category: 'Sorting',
      description: 'Grows a sorted prefix by inserting each value.',
      complexity: 'O(n²)',
      inputKind: InputKind.array,
    ),
    AlgorithmMeta(
      id: 'heap_sort',
      name: 'Heap Sort',
      category: 'Sorting',
      description: 'Repeatedly extracts the max from a binary heap.',
      complexity: 'O(n log n)',
      inputKind: InputKind.array,
    ),
    AlgorithmMeta(
      id: 'counting_sort',
      name: 'Counting Sort',
      category: 'Sorting',
      description: 'Counts occurrences, then rebuilds the array.',
      complexity: 'O(n + k)',
      inputKind: InputKind.array,
    ),
    AlgorithmMeta(
      id: 'radix_sort',
      name: 'Radix Sort',
      category: 'Sorting',
      description: 'Sorts one digit position at a time, LSD first.',
      complexity: 'O(dn)',
      inputKind: InputKind.array,
    ),
    AlgorithmMeta(
      id: 'bucket_sort',
      name: 'Bucket Sort',
      category: 'Sorting',
      description: 'Scatters values into buckets, sorts, concatenates.',
      complexity: 'O(n + k)',
      inputKind: InputKind.array,
    ),
    AlgorithmMeta(
      id: 'shell_sort',
      name: 'Shell Sort',
      category: 'Sorting',
      description: 'Insertion sort over shrinking gaps.',
      complexity: 'O(n²)',
      inputKind: InputKind.array,
    ),
    AlgorithmMeta(
      id: 'cocktail_sort',
      name: 'Cocktail Shaker Sort',
      category: 'Sorting',
      description: 'Bidirectional passes that shake values into place.',
      complexity: 'O(n²)',
      inputKind: InputKind.array,
    ),
    AlgorithmMeta(
      id: 'comb_sort',
      name: 'Comb Sort',
      category: 'Sorting',
      description: 'Insertion sort with a shrinking gap.',
      complexity: 'O(n²)',
      inputKind: InputKind.array,
    ),
    AlgorithmMeta(
      id: 'gnome_sort',
      name: 'Gnome Sort',
      category: 'Sorting',
      description: 'Walks back and forth until order is restored.',
      complexity: 'O(n²)',
      inputKind: InputKind.array,
    ),
    AlgorithmMeta(
      id: 'cycle_sort',
      name: 'Cycle Sort',
      category: 'Sorting',
      description: 'Writes each value directly to its final position.',
      complexity: 'O(n²)',
      inputKind: InputKind.array,
    ),
  ];

  static AlgorithmMeta byId(String id) => all.firstWhere((m) => m.id == id);

  static List<int> prepareInput(String id, List<int> input) {
    final copy = List<int>.from(input);
    if (id == 'binary_search') copy.sort();
    return copy;
  }

  static int binarySearchTarget(List<int> sorted) {
    final i = (sorted.length * 3) ~/ 4;
    return sorted[i < sorted.length ? i : sorted.length - 1];
  }

  static Iterable<VizEvent> generate({
    required String id,
    required List<int> array,
    required GraphModel graph,
    int start = 0,
  }) {
    switch (id) {
      case 'bubble_sort':
        return bubbleSort(array);
      case 'merge_sort':
        return mergeSort(array);
      case 'quick_sort':
        return quickSort(array);
      case 'binary_search':
        final sorted = prepareInput(id, array);
        return binarySearch(sorted, binarySearchTarget(sorted));
      case 'bfs':
        return bfs(graph, start: start);
      case 'dfs':
        return dfs(graph, start: start);
      case 'dijkstra':
        return dijkstra(graph, start: start);
      case 'selection_sort':
        return selectionSort(array);
      case 'insertion_sort':
        return insertionSort(array);
      case 'heap_sort':
        return heapSort(array);
      case 'counting_sort':
        return countingSort(array);
      case 'radix_sort':
        return radixSort(array);
      case 'bucket_sort':
        return bucketSort(array);
      case 'shell_sort':
        return shellSort(array);
      case 'cocktail_sort':
        return cocktailSort(array);
      case 'comb_sort':
        return combSort(array);
      case 'gnome_sort':
        return gnomeSort(array);
      case 'cycle_sort':
        return cycleSort(array);
      default:
        return const <VizEvent>[];
    }
  }
}