import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/algorithms/algorithm_registry.dart';
import '../../data/algorithms/event_engine.dart';
import '../../data/models/graph_model.dart';
import '../../data/models/viz_algorithm.dart';
import '../../data/models/viz_event.dart';

class AlgoVizState {
  const AlgoVizState({
    this.algorithmId = 'bubble_sort',
    this.array = const [29, 10, 14, 37, 14, 22, 8, 31],
    this.startNode = 0,
    this.events = const [],
    this.cursor = 0,
    this.playing = false,
    this.speedMs = 600,
    this.displayArray = const [29, 10, 14, 37, 14, 22, 8, 31],
    this.compare = const [],
    this.swap = const [],
    this.sorted = const {},
    this.pivot,
    this.rangeStart,
    this.rangeEnd,
    this.pointerL,
    this.pointerM,
    this.pointerR,
    this.message = 'Pick an algorithm and press Play',
    this.visited = const {},
    this.currentNode,
    this.activeEdge = const [],
    this.distances = const {},
    this.stats,
  });

  final String algorithmId;
  final List<int> array; // base input (editable)
  final int startNode;
  final List<VizEvent> events;
  final int cursor; // 0..events.length
  final bool playing;
  final int speedMs;
  // derived render state:
  final List<int> displayArray;
  final List<int> compare;
  final List<int> swap;
  final Set<int> sorted;
  final int? pivot;
  final int? rangeStart;
  final int? rangeEnd;
  final int? pointerL;
  final int? pointerM;
  final int? pointerR;
  final String message;
  final Set<int> visited;
  final int? currentNode;
  final List<int> activeEdge; // [from,to]
  final Map<int, double> distances;
  final VizStats? stats;

  AlgorithmMeta get meta => AlgorithmRegistry.byId(algorithmId);
  bool get isGraph => meta.inputKind == InputKind.graph;
  bool get isFinished => cursor >= events.length && events.isNotEmpty;
  double get progress => events.isEmpty ? 0 : cursor / events.length;

  AlgoVizState copyWith({
    String? algorithmId, List<int>? array, int? startNode,
    List<VizEvent>? events, int? cursor, bool? playing, int? speedMs,
    List<int>? displayArray, List<int>? compare, List<int>? swap,
    Set<int>? sorted, int? Function()? pivot, int? Function()? rangeStart,
    int? Function()? rangeEnd, int? Function()? pointerL,
    int? Function()? pointerM, int? Function()? pointerR,
    String? message, Set<int>? visited, int? Function()? currentNode,
    List<int>? activeEdge, Map<int, double>? distances, VizStats? stats,
  }) {
    return AlgoVizState(
      algorithmId: algorithmId ?? this.algorithmId,
      array: array ?? this.array,
      startNode: startNode ?? this.startNode,
      events: events ?? this.events,
      cursor: cursor ?? this.cursor,
      playing: playing ?? this.playing,
      speedMs: speedMs ?? this.speedMs,
      displayArray: displayArray ?? this.displayArray,
      compare: compare ?? this.compare,
      swap: swap ?? this.swap,
      sorted: sorted ?? this.sorted,
      pivot: pivot != null ? pivot() : this.pivot,
      rangeStart: rangeStart != null ? rangeStart() : this.rangeStart,
      rangeEnd: rangeEnd != null ? rangeEnd() : this.rangeEnd,
      pointerL: pointerL != null ? pointerL() : this.pointerL,
      pointerM: pointerM != null ? pointerM() : this.pointerM,
      pointerR: pointerR != null ? pointerR() : this.pointerR,
      message: message ?? this.message,
      visited: visited ?? this.visited,
      currentNode: currentNode != null ? currentNode() : this.currentNode,
      activeEdge: activeEdge ?? this.activeEdge,
      distances: distances ?? this.distances,
      stats: stats ?? this.stats,
    );
  }
}

class AlgoVizNotifier extends Notifier<AlgoVizState> {
  Timer? _timer;

  @override
  AlgoVizState build() {
    ref.onDispose(() => _timer?.cancel());
    final s = const AlgoVizState();
    return _rebuild(s, s.array, 0, generate: true);
  }

  // ---- public API used by Screen/Controls ----
  void selectAlgorithm(String id) {
    _stopTimer();
    final s = state.copyWith(algorithmId: id, playing: false);
    state = _rebuild(s, s.array, 0, generate: true);
  }

  void setArray(List<int> arr) {
    arr = arr.where((v) => v >= 0 && v <= 999).toList();
    if (arr.isEmpty || arr.length > 16) return;
    _stopTimer();
    final s = state.copyWith(array: arr, playing: false);
    state = _rebuild(s, arr, 0, generate: true);
  }

  void shuffleArray() {
    final rnd = math.Random();
    final arr = List<int>.from(state.array)..shuffle(rnd);
    setArray(arr);
  }

  void randomArray() {
    final rnd = math.Random();
    setArray(List.generate(8, (_) => 5 + rnd.nextInt(40)));
  }

  void setStartNode(int v) {
    _stopTimer();
    final s = state.copyWith(startNode: v, playing: false);
    state = _rebuild(s, s.array, 0, generate: true);
  }

  void setSpeed(int ms) => state = state.copyWith(speedMs: ms.clamp(100, 2000));

  void next() {
    if (state.cursor >= state.events.length) { pause(); return; }
    state = _rebuild(state, state.array, state.cursor + 1);
    if (state.cursor >= state.events.length) pause();
  }

  void prev() {
    if (state.cursor <= 0) return;
    _stopTimer();
    state = _rebuild(state.copyWith(playing: false), state.array, state.cursor - 1);
  }

  void reset() {
    _stopTimer();
    state = _rebuild(state.copyWith(playing: false), state.array, 0);
  }

  void play() {
    if (state.playing || state.isFinished && state.cursor >= state.events.length) {
      if (state.isFinished) reset();
    }
    state = state.copyWith(playing: true);
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: state.speedMs), (_) => next());
  }

  void pause() {
    _stopTimer();
    if (state.playing) state = state.copyWith(playing: false);
  }

  void _stopTimer() { _timer?.cancel(); _timer = null; }

  // ---- core: regenerate events, then replay 0..cursor ----
  AlgoVizState _rebuild(AlgoVizState s, List<int> base, int cursor, {bool generate = false}) {
    List<VizEvent> events = s.events;
    List<int> input = List<int>.from(base);
    if (generate || events.isEmpty) {
      if (s.algorithmId == 'binary_search') input = AlgorithmRegistry.prepareInput(s.algorithmId, base);
      events = AlgorithmRegistry.generate(
        id: s.algorithmId, array: input, graph: demoGraph, start: s.startNode,
      ).toList();
      cursor = 0;
    }
    // replay array mutations + stats up to cursor
    final arr = List<int>.from(input);
    final stats = VizStats();
    final sorted = <int>{};
    final visited = <int>{};
    final dist = <int, double>{};
    List<int> compare = [], swap = [], activeEdge = [];
    int? pivot, rs, re, pl, pm, pr, cur;
    String msg = events.isEmpty ? 'No steps' : (events.first.text ?? 'Ready — press Play');

    for (var i = 0; i < cursor && i < events.length; i++) {
      final e = events[i];
      applyEvent(arr, e);
      updateStats(stats, e);
      if (e.text != null) msg = e.text!;
      switch (e) {
        case CompareEvent(:final indices): compare = indices; swap = [];
        case SwapEvent(:final indices): swap = indices; compare = [];
        case MarkSortedEvent(:final indices): sorted.addAll(indices); compare = []; swap = [];
        case PivotEvent(:final index): pivot = index;
        case RangeEvent(:final start, :final end): rs = start; re = end;
        case PointersEvent(:final left, :final right, :final mid): pl = left; pr = right; pm = mid;
        case VisitEvent(:final node): visited.add(node); cur = node;
        case DequeueEvent(:final node): cur = node;
        case EnqueueEvent(:final node): cur = node;
        case RelaxEvent(:final from, :final to): activeEdge = [from, to];
        case DistanceEvent(:final node, :final distance): dist[node] = distance;
        case OverwriteEvent(): compare = []; swap = [];
        default: break;
      }
    }
    if (cursor >= events.length && events.isNotEmpty) {
      msg = events.last.text ?? 'Finished';
    }
    return s.copyWith(
      events: events, cursor: cursor, displayArray: arr,
      compare: compare, swap: swap, sorted: sorted,
      pivot: () => pivot, rangeStart: () => rs, rangeEnd: () => re,
      pointerL: () => pl, pointerM: () => pm, pointerR: () => pr,
      message: msg, visited: visited, currentNode: () => cur,
      activeEdge: activeEdge, distances: dist, stats: stats,
      array: base,
    );
  }
}

final algoVizProvider =
    NotifierProvider<AlgoVizNotifier, AlgoVizState>(AlgoVizNotifier.new);