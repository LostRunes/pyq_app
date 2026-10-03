import '../models/graph_model.dart';
import '../models/viz_event.dart';

String _l(GraphModel g, int id) => g.labelOf(id);

String _w(double weight) =>
    weight == weight.roundToDouble() ? weight.toStringAsFixed(0) : '$weight';

Iterable<VizEvent> bfs(GraphModel g, {int start = 0}) sync* {
  final seen = <int>{start};
  final queue = <int>[start];
  yield EnqueueEvent(start, text: 'Enqueue ${_l(g, start)}');
  while (queue.isNotEmpty) {
    final u = queue.removeAt(0);
    yield DequeueEvent(u, text: 'Dequeue ${_l(g, u)}');
    for (final e in g.incident(u)) {
      final v = g.other(e, u);
      yield RelaxEvent(u, v, text: 'Edge ${_l(g, u)}-${_l(g, v)} (w ${_w(e.weight)})');
      if (seen.add(v)) {
        yield EnqueueEvent(v, text: 'Enqueue ${_l(g, v)}');
        queue.add(v);
      }
    }
    yield VisitEvent(u, text: 'Visited ${_l(g, u)}');
  }
  yield MessageEvent('BFS complete, ${seen.length} nodes reached');
}

Iterable<VizEvent> dfs(GraphModel g, {int start = 0}) sync* {
  final seen = <int>{start};
  final stack = <int>[start];
  yield EnqueueEvent(start, text: 'Push ${_l(g, start)}');
  while (stack.isNotEmpty) {
    final u = stack.removeLast();
    yield DequeueEvent(u, text: 'Pop ${_l(g, u)}');
    for (final e in g.incident(u).toList().reversed) {
      final v = g.other(e, u);
      yield RelaxEvent(u, v, text: 'Edge ${_l(g, u)}-${_l(g, v)} (w ${_w(e.weight)})');
      if (seen.add(v)) {
        yield EnqueueEvent(v, text: 'Push ${_l(g, v)}');
        stack.add(v);
      }
    }
    yield VisitEvent(u, text: 'Visited ${_l(g, u)}');
  }
  yield MessageEvent('DFS complete, ${seen.length} nodes reached');
}

Iterable<VizEvent> dijkstra(GraphModel g, {int start = 0}) sync* {
  final dist = <int, double>{for (final n in g.nodes) n.id: double.infinity};
  final settled = <int>{};
  dist[start] = 0;
  yield DistanceEvent(start, 0, text: 'Distance ${_l(g, start)} = 0');
  while (settled.length < g.nodes.length) {
    int? u;
    for (final n in g.nodes) {
      if (settled.contains(n.id)) continue;
      final d = dist[n.id]!;
      if (d.isFinite && (u == null || d < dist[u]!)) u = n.id;
    }
    if (u == null) break;
    settled.add(u);
    yield DequeueEvent(u, text: 'Select ${_l(g, u)} with dist ${_fmt(dist[u]!)}');
    yield VisitEvent(u, text: 'Settled ${_l(g, u)}');
    for (final e in g.incident(u)) {
      final v = g.other(e, u);
      if (settled.contains(v)) continue;
      yield RelaxEvent(u, v, text: 'Edge ${_l(g, u)}-${_l(g, v)} (w ${_w(e.weight)})');
      final next = dist[u]! + e.weight;
      if (next < dist[v]!) {
        dist[v] = next;
        yield DistanceEvent(v, next, text: 'Dist ${_l(g, v)} = ${_fmt(next)}');
        yield EnqueueEvent(v, text: '${_l(g, v)} updated');
      }
    }
  }
  yield MessageEvent('Dijkstra complete from ${_l(g, start)}');
}

String _fmt(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';